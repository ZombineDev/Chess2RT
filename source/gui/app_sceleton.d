module gui.appsceleton;

import std.variant : Variant;

abstract class AppSceleton
{
    /// Main application loop
    /// Retruns:
    ///     true if the application is closing normally.
    bool run(Variant init_params = null)
    {
        init(init_params);

        while(handleInput())
        {
            update();
            render();
            display();
        }

        return true;
    }

    /// Initializes the application's resources.
    void init(Variant init_params);

    /// Handles the input.
    /// Returns:
    ///     false - if the app should be closed and true - otherwise.
    bool handleInput();

    /// Updates the application state after handling input.
    void update();

    /// Renders the next frame into an image.
    void render();

    /// Displays the rendered image.
    void display();
}
