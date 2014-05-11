Set Web UI Display Settings
---------------------------

Sets the display settings that the current user uses in the SuccessWhale web UI. Other clients can set these values too if they use them in a sensible way. It's important to note that none of the values you set here have any effect on the API &mdash; they are just stored so that the user can have a consistent experience across clients.

The optional parameters to set are the theme (`theme`), the number of columns displayed horizontally on a screen before scrolling (`colsperscreen`), the maximum age of items (in minutes) to draw a "this is new!" highlight box around (`highlighttime`), and whether to display media inline in columns in the client (`inlinemedia`).

* Request type: POST
* Authentication required: yes
* Required parameters: `token`
* Optional parameters: `theme`, `colsperscreen`, `highlighttime`, `inlinemedia`
* Return formats supported: JSON, XML

URL Format:

    /v3/displaysettings[.json|.xml]

Example Response (JSON):

    {
      "success":true
    }
