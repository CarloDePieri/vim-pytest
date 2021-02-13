import re
from typing import Dict
import xml.etree.ElementTree as ET


def _parse_testsuite(element) -> Dict:
    data = {
        "entries": [],
        "red": 0,
        "green": 0,
        "skip": 0
    }

    data["skip"] = int(element.get('skipped', "0"))
    data["red"] = int(element.get('failures', "0")) + int(element.get('errors', "0"))
    data["green"] = int(element.get('tests', "0")) - data["red"] - data["skip"]

    # build the parent map
    parent_map = {c: p for p in element.iter() for c in p}

    # build the errors map
    for error in element.iter('error'):
        parent = parent_map[error]

        # check if there has been a collection failure aka the syntax in a test file is broken
        if error.attrib.get('message', "") == "collection failure":
            r = r"#x1B\[1m#x1B\[31mE\ \ \ (.*)#x1B\[0m#x1B\[0m"
            message = re.search(r, error.text).groups()[0]
            r = r"File\ \"(.*)\", line\ (\d*)"
            found = re.search(r, error.text).groups()
            data["entries"].append({
                "text": f"{message}        <<Test collection error!>>",
                "type": "CollectionError",
                "lnum": int(found[1]),
                "col": 0,
                "length": 1,
                "filename": found[0]
            })
            # pytest only collected this error, should return now
            return data

        testname = parent.attrib["name"]
        r = r"#x1B\[31mE(.*)#x1B\[0m"
        message = re.search(r, error.text).groups()[0][7:]
        r = r"file\ (.*), line\ (\d*)"
        found = re.search(r, error.text).groups()
        data["entries"].append(
            {
                "text": f"{message}        ({testname})",
                "type": "BrokenTest",
                "lnum": int(found[1]),
                "col": 0,
                "length": 1,
                "filename": found[0],
            }
        )

    # build the failures entries
    for failure in element.iter('failure'):
        parent = parent_map[failure]
        testname = parent.attrib["name"]
        message = failure.attrib["message"].replace("\n +  ", "  |  ")

        stacktrace = failure.text
        delimiter = "_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ \n\n"
        r = r"#x1B\[1m#x1B\[31m(.*)#x1B\[0m:(\d*): (.*)"

        if delimiter in stacktrace:
            # More elements in the stacktrace means that the error generated outside the test
            traces = stacktrace.split(delimiter)
            # Add an entry for the failed test
            found = re.search(r, traces[0]).groups()
            data["entries"].append(
                {
                    "text": f"Failed test (see next)        ({testname})",
                    "type": "FailedTest",
                    "lnum": int(found[1]),
                    "col": 0,
                    "length": 1,
                    "filename": found[0]
                }
            )
            # Add an entry for the source of the stacktrace
            found = re.search(r, traces[-1]).groups()
            data["entries"].append(
                {
                    "text": f"> {found[2]}: {message}        ({testname})",
                    "type": ">",
                    "lnum": int(found[1]),
                    "col": 0,
                    "length": 1,
                    "filename": found[0]
                }
            )
        else:
            # Only one element in the stacktrace: the error is in the test
            found = re.search(r, stacktrace).groups()
            data["entries"].append(
                {
                    "text": f"{found[2]}: {message}        ({testname})",
                    "type": "FailedTest",
                    "lnum": int(found[1]),
                    "col": 0,
                    "length": 1,
                    "filename": found[0]
                }
            )
    return data


def parse_pytest_junit_report(path: str) -> Dict:
    """
    This will parse a pytest junit xml result file, returning it as a dictionary with
    the following fields:

    - green: the number of passed tests
    - red: the number of tests that failed or reported an error
    - skip: the number of skipped tests
    - entries: a list of neomake location/quick fix window entries
    """
    data = {
        "entries": [],
        "red": 0,
        "green": 0,
        "skip": 0
    }
    with open(path, "r") as f:
        raw = f.read()
        # Fix ascii color escape characters
        raw = raw.replace("", "#x1B")
    # Parse the xml report
    tree = ET.fromstring(raw)

    for testsuite in tree.findall('testsuite'):
        suitedata = _parse_testsuite(testsuite)
        data["red"] += suitedata["red"]
        data["green"] += suitedata["green"]
        data["skip"] += suitedata["skip"]
        data["entries"] += suitedata["entries"]

    return data
