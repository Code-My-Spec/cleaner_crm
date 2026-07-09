# Phoenix.Flash

Provides shared flash access.

## get/2

Gets the key from the map of flash data.

## Examples

```heex
<div id="info"><%= Phoenix.Flash.get(@flash, :info) %></div>
<div id="error"><%= Phoenix.Flash.get(@flash, :error) %></div>
```