Delete Item
-----------

Deletes an item (that you have permission to delete). Takes the ID of an item (`postid`), plus the service (`service`) and user ID (`uid`) to perform the action as.

* Request type: DELETE
* Authentication required: yes
* Required parameters: `token`, `service`, `uid`, `postid`
* Optional parameters: none
* Return formats supported: JSON, XML

URL Format:

    /v3/item[.json|.xml]

Example Response (JSON):

    {
      "success":true
    }
