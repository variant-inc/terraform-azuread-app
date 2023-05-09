# Testing

This document provides a guide on how to deploy
new apps on Azure using terraform-azuread-spa
and test it to get an access token.

1. Pull the latest changes from the master branch or the branch under validation
2. We need to authenticate to Azure and AWS for us to run the terraform so,
   lets store them as environment variables as shown.
3. For authenticating to Azure: Please ping me in Slack or Teams for this info!

    ```shell
    ### sh
    export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
    export ARM_CLIENT_SECRET="MyCl1eNtSeCr3t"
    export ARM_TENANT_ID="10000000-2000-3000-4000-500000000000"
    ```

    ```powershell
    ### PowerShell
    $env:ARM_CLIENT_ID = "00000000-0000-0000-0000-000000000000"
    $env:ARM_CLIENT_SECRET = "MyCl1eNtSeCr3t"
    $env:ARM_TENANT_ID = "10000000-2000-3000-4000-500000000000"
    ```

4. For authenticating to AWS click on the account you would
   like to use and select “Command Line or programmatic access”
   and select Option 1: Set AWS environment variables.
5. Open the repo in the editor of your choice and
   add a new file terraform.tfvars.json.
   Add the following contents into this file:

    ```json
    {
        "name": "tfspa-demo",
        "environment": "dpl",
        "tags": {
            "team": "devops",
            "owner": "devops",
            "purpose": "testing",
            "project": "actions-test",
            "space": "Default",
            "environment": "development",
            "project_group": "Default Project Group",
            "release_channel": "feature"
        },
        "group_roles_assignment": [
          {
            "name": "Existing-Group-1",
            "roles": [
              "abcd",
              "efgh"
            ]
          },
          {
            "name": "Existing-Group-2",
            "roles": [
              "abcd",
              "efgh",
              "hjkl"
            ]
          },
          {
            "name": "Existing-Group-3",
            "roles": [
              "abcd"
            ]
          }
        ],
      "api_apps": ["Api-Application-1", "Api-Application-2"],
      "service_app_roles_assignment": [
          {
            "name": "service-app-1",
            "roles": [
              "abcd"
            ]
          },
          {
            "name": "service-app-2",
            "roles": [
              "efgh",
              "hjkl"
            ]
          }
      ],
      "redirect_uris": ["https://localhost:5001/login"]
    ```

6. Change all the variable details like name, environment,
   group_roles_assignment and service_app_roles_assignment as needed.

    > NOTE: The variable group_roles_assignment
    > or service_app_roles_assignment can be left empty as per your needs!

7. Now we have everything we need so, let go ahead and run the following commands

    ```shell
    terraform init
    terraform plan
    terraform apply
    ```

8. Once the apply is successful, we can see the direct
   links of the groups created on Azure as a part of the outputs.
   The owners mentioned in the tfvars.json variable owners
   will now have access to it and can add members to the roles as required.
9. Go to the AWS secrets manager to retrieve the secret value.
    Here you can find all the details needed for us to get an access token
10. For testing this out please install [Postman](https://www.postman.com/downloads/)
11. Go to collections tab found on the left hand side
    and Click on “+” to create a new collection.
12. Select ‘OAuth2’ as the type of Authorization as shown
13. If you are trying to access the app as an
    individual user then Select ‘Authorization Code’ as the Grant Type.
14. If you are trying to access the app through
    one of the service apps then select ‘Client Credentials’ as the Grant Type.

    > NOTE: For service to service calls the Access Token URL is
    > [https://login.microsoftonline.com/{{tenant-id}}/oauth2/token](https://login.microsoftonline.com/%7b%7btenant-id%7d%7d/oauth2/token)
    > whereas when we are trying to access the
    > application as a user the Access Token URL is
    > [https://login.microsoftonline.com/{{tenant-id}}/oauth2/v2.0/token](https://login.microsoftonline.com/%7b%7btenant-id%7d%7d/oauth2/v2.0/token)

15. Fill in the required details.
    You can find the client id of the service apps
    in the output and the Client Secret in the AWS Secrets Manager.
16. Because we are trying to access our main application
    with this service app we need to provide the resource.
17. In the tab next to Configuration Options please
    select ‘Advanced Options’ and set the resource to the
    Application ID URI of the target app. You can find this in the output.
18. After filling in all these details, click on Get a new Access token.
19. If you are accessing the app as a user you would
    have to login using your USX email and password for getting the token..
20. To validate the token please copy the access token
    (id token when you are logging in as a user) and go to <https://jwt.io/>
21. Paste the copied token in the encoded area on the left side.
    On the right side we can see the decoded value.
    In here we should also be able to see the roles
    of the user or the service apps.
