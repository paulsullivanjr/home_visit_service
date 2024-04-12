# Home Visit Service

## Overview

The Home Visit Service application is designed to manage visits where users can be either members requesting visits or pals fulfilling these visits. Members have a certain number of visit minutes, which are debited from their account when a visit is completed by a pal. A pal gets minutes credited to their account, with an overhead fee deducted. If a member run out ot minutes, they cannot requests a pal visit until they have completed a visit themselves to earn minutes.

## Getting Started

### Prerequisites

- Elixir 1.16.0-otp-26
- Erlang 26.2.1
- SQLite for the database


### Installation

Clone the repository and fetch the dependencies:

```bash
git clone https://github.com/paulsullivanjr/home_visit_service.git

cd home_visit_service
``` 

Make sure you have `asdf` installed to manage the versions of Erlang and Elixir. The `.tool-versions` file in the project root will install the right versions when you navigate into the root directory of the project and run the following command.

```
asdf install
```

Get dependencies and setup database
```
mix deps.get && mix deps.compile
mix ecto.create
mix ecto.migrate

MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
```

### Running the Application

```elixir

iex -S mix

# These are the functions to run through the flow. See the HomeVisitService module for additional utility functions.

{:ok, member} = HomeVisitService.create_user("John", "Memory", "member@example.com")

{:ok, pal} = HomeVisitService.create_user("Pal", "Pallerson", "pal@example.com")

{:ok, visit} = HomeVisitService.request_visit(member.id, DateTime.utc_now(), 60, "Companionship")

available_visits = HomeVisitService.available_visits_for_pal(pal.id)

{:ok, accepted_visit} = HomeVisitService.accept_visit(visit.id, pal.id)

{:ok, compoleted_visit} = HomeVisitService.complete_visit(accepted_visit, member.id)

transactions = HomeVisitService.get_visit_transactions(visit.id)

```

### Assumptions
- Seeding users with 180 minutes
- Duration for visits
- Visits can not be deleted.
- The requestor is the person who "completes" the visit.
- No focus specifically on performance.


### Design Decisions
My approach to any project is thinking about API's and layers. My goal is to have context modules act as the API for data access and then have module(s) that provide an API around the context modules. This layer would be the entry point into the application. For testing my goal was to have a single test file for the main API module that would provide test coverage of the functions from the context module as well. 

I also try to keep functions simple and explicit. This includes changeset functions as well. I've found it is often easier to just have multiple changeset functions that are more explicit than having a single changeset function in a schema module. I've tried to name functions as clearly as possible and always keep then in the main API since that is where the interaction with the outside world will happen.

For tracking the visit minutes for members and pals, I opted to use the following types for transactions: `:debit`, `:credit` and `:credit_add`. I use an `Ecto.Multi` to guarantee two transactions are created for each visit. One for the minutes being deducted from the member, and the other being crediting minutes (minus 15% overhead) to the pal. The `:credit_add` transaction type is used for initial seeding of minutes for a member to start with (180 minutes default) and not exposed through the main API. This structure of tracking debits, credits, and credit adds allows me to think about the process more like a checkbook register and simplify calculations to know how many minutes are available for a member. The visits also contain a minutes duration so that I can verify they have enough minutes to cover the request. This check gets the current balance of minutes minus and any pending requests which results in a net number of available minutes.  


I decided to use `DateTime.utc_now()` for all date functionality. Dates can be tricky to deal with and with the scope of this challenge I decided to focus on other areas. I am not honoring the date on the visits, but I do store it. It provides a way to enhance it later to properly handle dates. 

Due to the nature of the code challenge, I made no special considerations for performance. If there is a single bottleneck I could identify, it would be the tracking of debits and credits on transactions. As the application grows it could result in a significant hit in performance to make the database calls on demand. Before taking any action to improve performance, it would be best to gather data using logs and metrics to determine the impact to performance and where to focus efforts. Once the determination is made based on the data, various options could be investigated including query optimization, index improvements, and caching.


### Technical Choices
Since the challenge only requires a REPL interface I opted for an Elixir app instead of a Phoenix application.

Dependencies:
- `ecto_sql` - Ecto support 
- `ecto_sqlite3` - SQLite database
- `faker` - Used to help generate random email addresses


The structure of the project is:
- `/db` - Directory for the SQLite databases, one for dev, one for test
- `lib/schemas` - All of the project schemas and changeset functions
- `lib/contexts` - Context modules that create the API around each schema
- `lib/home_vist_service.ex` - The main API for the application. 
- `.tool-versions` - Used to install Elixir/Erlang for this application

The rest of the application structure consists of normal structure provided by default or added as part of using Ecto.
