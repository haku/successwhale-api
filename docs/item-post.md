Post Item
---------

Posts an item (`text`) to one or more accounts defined by `accounts`. If no accounts are supplied, it uses the user's defaults (those that show up as enabled in the `posttoaccounts` call). (THE DEFAULT FEATURE IS NOT YET IMPLEMENTED)

An optional `in_reply_to_id` parameter converts the post from a normal post into a reply. In the case of Twitter, this will be a normal post with the `in_reply_to_status_id` parameter set. For Facebook and LinkedIn, this will be a comment attached to an existing post.

* Request type: POST
* Authentication required: yes
* Required parameters: `text`
* Optional parameters: `sw_uid`, `secret`, `accounts`, `in_reply_to_id`
* Return formats supported: JSON, XML

URL Format:

    /v3/item[.json|.xml]

Example Response (JSON):

    {
      "success":true
    }
