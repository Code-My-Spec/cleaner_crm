# Credo.Code.Module

This module provides helper functions to analyse modules, return the defined
functions or module attributes.

## aliases/1

Returns the list of aliases defined in a given module source code.

## attribute/2

Reads an attribute from a module's `ast`

## def_count/1

Returns the function/macro count for the given module's AST

## def_arity/1

Returns the arity of the given function definition `ast`

## def_name/1

Returns the name of the function/macro defined in the given `ast`

## def_name_with_op/1

Returns the {fun_name, op} tuple of the function/macro defined in the given `ast`

## def_names/1

Returns the name of the functions/macros for the given module's `ast`

## def_names_with_op/1

Returns the name of the functions/macros for the given module's `ast`

## def_names_with_op/2

Returns the name of the functions/macros for the given module's `ast` if it has the given `arity`.

## modules/1

Returns the list of modules used in a given module source code.

## name/1

Returns the name of a module's given ast node.