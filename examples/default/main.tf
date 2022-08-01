module "terraform_azuread_spa" {
  source      = "../"
  name        = "test-azure-app-sathwik"
  environment = "dpl"
  tags = {
    "team" : "devops",
    "owner" : "devops",
    "purpose" : "testing",
    "project" : "actions-test",
    "space" : "Default",
    "environment" : "development",
    "project_group" : "Default Project Group",
  "release_channel" : "feature" }
  group_roles_assignment = [
    {
      "name" : "group-name1",
      "roles" : [
        "abcd",
        "efgh"
      ]
    },
    {
      "name" : "group-name2",
      "roles" : [
        "abcd",
        "efgh",
        "hjkl"
      ]
    },
    {
      "name" : "group-name3",
      "roles" : [
        "abcd",
        "wxyz"
      ]
    }
  ]
  api_apps       = ["Some_Application_1", "Some_Application_2"]
  redirect_uris = ["https://localhost:8080/api/test"]
}
