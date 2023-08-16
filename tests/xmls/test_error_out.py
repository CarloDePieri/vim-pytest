import pytest

def outside():
    raise RuntimeError()

@pytest.fixture
def my_fixture():
    outside()

def test_error(my_fixture):
    my_fixture()
    assert True
