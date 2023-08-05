import pytest
from autoload.neomake.makers.python.lib import parse_pytest_junit_report
from pathlib import Path


xml_folder = Path("tests") / "xmls"


class TestAJunitReporParser:
    """A JUnit repor parser..."""

    def test_should_handle_non_existing_xml_files(self):
        """... it should handle non existing xml files"""
        data = parse_pytest_junit_report(str(xml_folder / "not-there.xml"))
        assert data["red"] == 1
        entry = data["entries"][0]
        assert entry["text"] == "Execution error. Check :PytestOutput"
        assert entry["type"] == "E"

    def test_should_handle_successful_runs(self):
        """... it should handle successful runs"""
        data = parse_pytest_junit_report(str(xml_folder / "success.xml"))
        assert data["green"] == 1

    @pytest.mark.parametrize("test_file", ["fail_in_color.xml", "fail_in_nocolor.xml"])
    def test_should_handle_failed_in_tests(self, test_file):
        """... it should handle failed in tests"""
        data = parse_pytest_junit_report(str(xml_folder / test_file))
        assert data["red"] == 1
        entry = data["entries"][0]
        assert entry["type"] == "FailedTest"

    @pytest.mark.parametrize(
        "test_file", ["fail_out_color.xml", "fail_out_nocolor.xml"]
    )
    def test_should_handle_failed_out_tests(self, test_file):
        """... it should handle failed out tests"""
        data = parse_pytest_junit_report(str(xml_folder / test_file))
        assert data["red"] == 1
        assert len(data["entries"]) == 2
        failed = data["entries"][0]
        origin = data["entries"][1]
        assert failed["type"] == "FailedTest"
        assert origin["type"] == ">"

    @pytest.mark.parametrize("test_file", ["error_color.xml", "error_nocolor.xml"])
    def test_should_handle_errors(self, test_file):
        """... it should handle errors"""
        data = parse_pytest_junit_report(str(xml_folder / test_file))
        assert data["red"] == 1
        entry = data["entries"][0]
        assert entry["type"] == "BrokenTest"

    @pytest.mark.parametrize(
        "test_file", ["syntax_error_color.xml", "syntax_error_nocolor.xml"]
    )
    def test_should_handle_syntax_errors(self, test_file):
        """... it should handle syntax errors"""
        data = parse_pytest_junit_report(str(xml_folder / test_file))
        assert data["red"] == 1
        entry = data["entries"][0]
        assert entry["type"] == "CollectionError"
