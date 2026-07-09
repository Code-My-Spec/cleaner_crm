# Plug.Swoosh.MailboxPreview

Plug that serves pages useful for previewing emails in development.

- `:csp_nonce_assign_key` - a map of keys to assign to the conn.assigns.
  - `:script` - the key to assign the script CSP nonce to
  - `:style` - the key to assign the style CSP nonce to

## Examples

    # in a Phoenix router
    defmodule Sample.Router do
      scope "/dev" do
        pipe_through [:browser]
        forward "/mailbox", Plug.Swoosh.MailboxPreview,
          csp_nonce_assign_key: %{script: :script_csp_nonce, style: :style_csp_nonce}
      end
    end