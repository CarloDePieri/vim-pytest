import os
import re
from typing import Dict, Optional, List, Union
import xml.etree.ElementTree as ET


def parse_pytest_junit_report(path: str) -> Dict:
    """
    This will parse a pytest junit xml result file, returning it as a dictionary with
    the following fields:

    - green: the number of passed tests
    - red: the number of tests that failed or reported an error
    - skip: the number of skipped tests
    - entries: a list of neomake location/quick fix window entries
    """
    data = {"entries": [], "red": 0, "green": 0, "skip": 0}

    try:
        with open(os.path.abspath(path), "r") as f:
            raw = f.read()
            # Fix ascii color escape characters
            raw = raw.replace("", "#x1B")
        # Parse the xml report
        tree = ET.fromstring(raw)

        for testsuite in tree.findall("testsuite"):
            suitedata = _parse_testsuite(testsuite)
            data["red"] += suitedata["red"]
            data["green"] += suitedata["green"]
            data["skip"] += suitedata["skip"]
            data["entries"] += suitedata["entries"]
    except (Exception,) as e:
        # Uncomment the following to ignore this try/except while coding
        #  raise e
        data["entries"].append(
            {
                "text": "Execution error. Check :PytestOutput",
                "type": "E",
                "lnum": 1,
                "col": 0,
                "length": 1,
                "filename": "",
            }
        )
        data["red"] = 1

    return data


def _parse_testsuite(element) -> Dict[str, Union[str, int, List[Dict[str, Union[str, int]]]]]:
    """Parse the junit test suite result and return a dict containing the parsed data."""
    data = {"entries": [], "red": 0, "green": 0, "skip": 0}

    data["skip"] = int(element.get("skipped", "0"))
    data["red"] = int(element.get("failures", "0")) + int(element.get("errors", "0"))
    data["green"] = int(element.get("tests", "0")) - data["red"] - data["skip"]

    # build the parent map
    parent_map = {c: p for p in element.iter() for c in p}

    # build the errors map
    for error in element.iter("error"):
        parent = parent_map[error]
        message = error.attrib.get("message", "")

        # check if there has been a collection failure aka the syntax in a test file is broken
        if message == "collection failure":
            parsed = _parse_syntax_error_stacktrace(error.text)
            data["entries"].append(
                {
                    "text": f"{parsed['message']}        <<Test collection error!>>",
                    "type": "CollectionError",
                    "lnum": int(parsed["line"]),
                    "col": 0,
                    "length": 1,
                    "filename": parsed["file"],
                }
            )
            # pytest only collected this error, should return now
            return data

        # These errors are usually errors in fixtures
        testname = parent.attrib["name"]

        data["entries"] += _create_data_entries(
            stacktrace=error.text,
            message=message,
            e_type="BrokenTest",
            text="Broken test",
            testname=testname,
        )

    # build the failures entries
    for failure in element.iter("failure"):
        parent = parent_map[failure]
        testname = parent.attrib["name"]
        message = failure.attrib["message"].replace("\n +  ", "  |  ")
        stacktrace = failure.text
        data["entries"] += _create_data_entries(
            stacktrace=stacktrace,
            message=message,
            e_type="FailedTest",
            text="Failed test",
            testname=testname,
        )

    return data


def _parse_syntax_error_stacktrace(stacktrace: str) -> Dict[str, str]:
    """
    Parse a test (containing a syntax error) stacktrace, returning a dict with 'file', 'line' and 'message'.
    """
    found = re.finditer(ERROR_REGEX, stacktrace, re.MULTILINE)
    if found:
        parsed = {}
        for match in found:
            group = match.group
            if group("message_c"):
                parsed["message"] = group("message_c")
            elif group("message_n"):
                parsed["message"] = group("message_n")
            elif group("line") or group("file"):
                parsed["line"] = group("line")
                parsed["file"] = group("file")
            else:
                raise WrongRegexException()
        if (
            not parsed.get("line")
            or not parsed.get("file")
            or not parsed.get("message")
        ):
            raise WrongRegexException()
        return parsed
    else:
        raise WrongRegexException()


def _create_data_entries(
    stacktrace: str, message: str, e_type: str, text: str, testname: str
) -> List[Dict[str, Union[str, int]]]:
    """Parse the stacktrace and return a dict contained the parsed data entries."""
    entries: List[Dict[str, Union[str, int]]] = []

    delimiter = _get_stacktrace_delimiter(stacktrace)

    if delimiter:
        # More elements in the stacktrace means that the error generated outside the test
        traces = stacktrace.split(delimiter)
        # Add an entry for the test that started the trace
        test = _parse_stacktrace(traces[0], ["line", "file"])
        entries.append(
            {
                "text": f"{text} (see next)        ({testname})",
                "type": e_type,
                "lnum": int(test["line"]),
                "col": 0,
                "length": 1,
                "filename": test["file"],
            }
        )
        # Add an entry for the line that originated the error
        origin = _parse_stacktrace(traces[-1])
        entries.append(
            {
                "text": f"> {origin['message']}: {message}        ({testname})",
                "type": ">",
                "lnum": int(origin["line"]),
                "col": 0,
                "length": 1,
                "filename": origin["file"],
            }
        )
    else:
        # Only one element in the stacktrace: the error is in the test
        test = _parse_stacktrace(stacktrace)
        entries.append(
            {
                "text": f"{test['message']}: {message}        ({testname})",
                "type": e_type,
                "lnum": int(test["line"]),
                "col": 0,
                "length": 1,
                "filename": test["file"],
            }
        )
    return entries


def _get_stacktrace_delimiter(stacktrace: str) -> Optional[str]:
    """Return the stacktrace delimiter, if found, None otherwise."""
    for line in stacktrace.splitlines():
        if line.startswith("_ _"):
            return line
    return None


def _parse_stacktrace(
    stacktrace: str, keys: List[str] = ["file", "line", "message"]
) -> Dict[str, str]:
    """
    Parse a failed or with error test stacktrace, returning a dict with 'file', 'line' and 'message'.
    Desired fields can be selected with the `keys` argument.
    """
    found = re.search(FAILURE_REGEX, stacktrace, re.MULTILINE)
    if found:
        parsed = {}
        group = found.group
        # find out which groups should be selected: c(color) or n(no color)
        color = "c" if group("line_c") else "n"
        for key in keys:
            name = f"{key}_{color}"
            # ensure the requested group have indeed been captured
            if not group(name):
                raise WrongRegexException()
            parsed[key] = group(name)
        # return the selected keys
        return parsed
    else:
        raise WrongRegexException()


class WrongRegexException(Exception):
    """Raised if the regex did not match (it should, by design!)"""


#
# Regexes are down here because they mess vim indentation for some reason
#
FAILURE_REGEX = r"^(?:#x1B\[1m#x1B\[31m)(?P<file_c>\S*)(?:#x1B\[0m:)(?P<line_c>\d*): (?P<message_c>.*)|^(?P<file_n>\S*):(?P<line_n>\d*): (?P<message_n>.*)"
ERROR_REGEX = r"(?:#x1B\[1m#x1B\[31mE\ \ \ )(?P<message_c>.*)(?:#x1B\[0m#x1B\[0m)|(?:^E\ \ \ )(?P<message_n>\S.*)|(?:File\ \")(?P<file>.*)(?:\", line\ )(?P<line>\d+)"
