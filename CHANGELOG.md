### v0.14 - March 02th, 2023 - Jungsoft version:
- Do not serialize nested associations when action is `update` and changes are empty
- Add `event` and `data` info when serializing an association with `action == :replace`
- Add `event` and `changes` info when serializing an association with `action != :replace`

#### Details

Before, when serializing nested associations, we could have empty maps in the JSON, since we were only serializing the `changes` from the Changeset. Now we have more information about whats going on on these associations.

Suppose we have a Post struct and a Comment struct that is associated with Post (with `has_many`):

```elixir
%Post{
  title: "Example post", 
  description: "...", 
  comments: [
    %{Comment{id: 1, text: "comment 1"},
    %{Comment{id: 2, text: "comment 2"},
    %{Comment{id: 3, text: "comment 3"},
  ]
}

# Now we update the posts with these attrs:

%{comments: [
  %{id: 1, text: "comment 1 updated"},
  %{id: 2, text: "comment 2"},
  %{text: "new comment"},
]}

# before, the serialized `item_changes` in the `versions` table would be:

%{"comments" => [
  {"text" => "comment 1 updated"},
  {}, # this is the comment 2, without any changes
  {}, # This is the comment 3, deleted because it was not in the attrs and there's no changes in the Changeset. changeset.action is set to replace
  {"text" => "new comment"},
]}

# now, it will be serialized as this:

%{"comments" => [
  {"event" => "update", "changes" => %{"text" => "comment 1 updated"}},
  {"event" => "replace", "data" => %{"text" => "comment 3"}},
  {"event" => "insert", "changes" => %{"text" => "new comment"}},
]}

# Notice that we removed serialization of associations with empty changes when it's an update action.
```

### v0.13 - November 10th, 2022 - Jungsoft version:
- Add support for Ecto 3.9.0

### v0.12 - August 24th, 2022 - Jungsoft version:
- Add support for Ecto 3.8
- Remove workaround from v0.11.1

### v0.11.1 - January 25th, 2022 - Jungsoft version:
- Add workaround for wrong `Ecto.Multi.insert_all` typespec (https://github.com/elixir-ecto/ecto/pull/3781)

### v0.11.0 - January 24th, 2022 - Jungsoft version:
- Chunk attributes when doing `insert_all` to not reach Postgres limit of 65535 query parameters.

### October 22th, 2021 - Jungsoft version:
- Save changes for nested associations.
- Deal with changes that have embedded schemas.
- Get the correct type of `originator_id` when building versions for update.
### https://github.com/nash-io/paper_trail/ version:
- Support multiple Repos.
- Support `update_all` operation.
- Improve serialization for non string Ecto types.
- Do not create version when there are no changes.
### v0.8.3 - September 10th, 2019:
- PaperTrail.delete now accepts Ecto.Changeset

### v0.8.2 - June 29th, 2019:
- Rare PaperTrail.RepoClient.repo compile time errors fixed.

##### ... many changes

### v0.6.0 - March 14th, 2017:
- Version event names are now 'insert', 'update', 'delete' to match their Ecto counterpats instead of 'create', 'update', 'destroy'.
- Introduction of strict mode. Please read the documentation for more information on the required origin and originator_id field and foreign-key references.
