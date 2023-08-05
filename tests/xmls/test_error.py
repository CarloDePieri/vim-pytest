import pytest


@pytest.fixture
def my_fixture():
    raise RuntimeError()


def test_error(my_fixture):
    my_fixture()
    assert True
