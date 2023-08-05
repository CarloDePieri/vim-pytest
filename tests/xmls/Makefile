all:
	poetry run pytest --junitxml=success.xml test_success.py; \
		PY_COLORS=0 poetry run pytest --junitxml=fail_in_nocolor.xml test_fail_in.py; \
		PY_COLORS=1 poetry run pytest --junitxml=fail_in_color.xml test_fail_in.py; \
		PY_COLORS=0 poetry run pytest --junitxml=fail_out_nocolor.xml test_fail_out.py; \
		PY_COLORS=1 poetry run pytest --junitxml=fail_out_color.xml test_fail_out.py; \
		PY_COLORS=1 poetry run pytest --junitxml=error_color.xml test_error.py; \
		PY_COLORS=0 poetry run pytest --junitxml=error_nocolor.xml test_error.py; \
		PY_COLORS=1 poetry run pytest --junitxml=syntax_error_color.xml test_syntax_error.py; \
		PY_COLORS=0 poetry run pytest --junitxml=syntax_error_nocolor.xml test_syntax_error.py
