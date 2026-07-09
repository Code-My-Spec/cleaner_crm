# Comeonin.BehaviourTestHelper

Test helper functions for Comeonin behaviours.

## ascii_passwords/0

List of passwords that just contain basic ascii characters.

## non_ascii_passwords/0

List of passwords that contain non-ascii characters.

## correct_password_true/2

Checks that the `verify_pass/2` function returns true for correct password.

## wrong_password_false/2

Checks that the `verify_pass/2` function returns false for incorrect passwords.

## add_hash_creates_map/2

Checks that the `add_hash/2` function creates a map with the `password_hash` set.

## check_pass_returns_user/2

Checks that the `check_pass/3` function returns the user for correct passwords.

## check_pass_returns_error/2

Checks that the `check_pass/3` function returns an error for incorrect passwords.

## check_pass_nil_user/1

Checks that the `check_pass/3` function returns an error when no user is found.