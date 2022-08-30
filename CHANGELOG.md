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
