#!/bin/bash
# Copyright (c) 2022-2025, AllWorldIT.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.


fdc_test_start request-tracker "Check Nginx is responding using IPv4..."
if ! curl --verbose --ipv4 "$NGINX_HEALTHCHECK_URI" --output test.out; then
	fdc_test_fail request-tracker "Failed to get test data from Nginx using IPv4"
	false
fi

if ! grep '<title>Login</title>' test.out; then
	fdc_test_fail request-tracker "Contents of output does not match what it should be using IPv4"
	false
fi

fdc_test_pass request-tracker "Nginx is responding using IPv4"


# Return if we don't have IPv6 support
if [ -z "$(ip -6 route show default)" ]; then
	fdc_test_alert powerdns "Not running IPv6 tests due to no IPv6 default route"
	return
fi


fdc_test_start request-tracker "Check Nginx is responding using IPv6..."
if ! curl --verbose --ipv6 "$NGINX_HEALTHCHECK_URI" --output test.out; then
	fdc_test_fail request-tracker "Failed to get test data from Nginx using IPv6"
	false
fi

if ! grep '<title>Login</title>' test.out; then
	fdc_test_fail request-tracker "Contents of output does not match what it should be using IPv6"
	false
fi

fdc_test_pass request-tracker "Nginx is responding"
