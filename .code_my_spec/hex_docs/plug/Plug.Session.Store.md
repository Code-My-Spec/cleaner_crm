# Plug.Session.Store

Specification for session stores.

## get/1

Gets the store name from an atom or a module.

    iex> Plug.Session.Store.get(CustomStore)
    CustomStore

    iex> Plug.Session.Store.get(:cookie)
    Plug.Session.COOKIE