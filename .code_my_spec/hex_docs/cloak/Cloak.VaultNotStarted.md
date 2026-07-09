# Cloak.VaultNotStarted

This exception indicates that your vault process hasn't been started yet. Before 
calling any vault functions, you must either:

#### 1. Call `start_link/0` on your vault module

    MyApp.Vault.start_link()

#### 2. Ensure your application is started
If your vault module has been added to your application supervision tree, make
sure your application is running before calling any vault functions.

    Application.ensure_all_started(:my_app)