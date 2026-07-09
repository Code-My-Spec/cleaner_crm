# Phoenix.LiveView.Helpers



## sigil_L/2

Provides `~L` sigil with HTML safe Live EEx syntax inside source files.

    iex> ~L"""
    ...> Hello <%= "world" %>
    ...> """
    {:safe, ["Hello ", "world", "\n"]}