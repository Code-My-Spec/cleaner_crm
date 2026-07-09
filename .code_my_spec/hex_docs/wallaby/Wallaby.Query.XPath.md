# Wallaby.Query.XPath



## link/1

XPath for links

This xpath is gracious ripped from capybara via
https://github.com/jnicklas/xpath/blob/master/lib/xpath/html.rb

## button/1

Match any clickable buttons

## radio_button/1

Match any radio buttons

## fillable_field/1

Match any `input` or `textarea` that can be filled with text.
Excludes any inputs with types of `submit`, `image`, `radio`, `checkbox`,
`hidden`, or `file`.

## checkbox/1

Match any checkboxes

## select/1

Match any `select` by name, id, or label.

## option/1

Match any `option` by visible text

## file_field/1

Matches any file field by name, id, or label

## text/1

Matches any element by its inner text.

## attribute/2

Matches any element by its attribute name and value pair.