def outside():
    raise Exception()
    return True

def test_fail():
    assert outside()
