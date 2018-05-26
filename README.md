# Rock-Paper-Scissors Multiplayer Game
> ### Rock-Paper-Scissors Multiplayer Game using Phoenix Framework.
> – This is just an example, just for fun!

About the example or exercise:

  * The logic of the game (game session handling) is implemented using
    [gen_statem](http://erlang.org/doc/man/gen_statem.html) behaviour.
  * REST API using Phoenix (to allow users to create new match games and play)
  * Authentication for REST API using [Guardian](https://github.com/ueberauth/guardian)
  * Leaderboard is implemented using ETS tables
  * Notifications about the round and the game using Phoenix Channels

> **Still WIP !!**

## Requirements

In order to be able to run the app you need:

  * Erlang 20 or higher
  * Elixir 1.5 or higher
  * PostgreSQL database

> **NOTE:** Remember to replace the PostgreSQL credentials in `config/dev.exs`
  and also `config/test.exs`.

## Running the app

To start your Phoenix server:

  * Install dependencies with: `mix deps.get`
  * Create and migrate your database with: `mix ecto.create && mix ecto.migrate`
  * Start the app endpoint with: `mix phx.server`
  * Start the app in interactive console: `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Testing

Before to run the tests, remember to change the DB credentials in
`config/test.exs`. Then you can run the tests:

```
$ mix test
```

If you want to enable test coverage:

```
$ MIX_ENV=test mix coveralls.html
```

And to see the coverage result you can open `cover/excoveralls.html`

## Getting started

In order to understand how the app works, let's play!

First, let's prepare the DB:

```
$ mix ecto.create
$ mix ecto.migrate
$ mix run priv/repo/seeds.exs
```

The seed will create 3 users: `user1`, `user2` and `admin` (password is the
same username)

Then run the server:

```
$ iex -S mix phx.server
```

### Authentication (Requesting Tokens)

In order to start playing, we need to request a token for the players; in our
case `user1` and `user2`. For example, to get a token for `user1`:

```
$ curl -vX POST \
  http://localhost:4000/api/v1/login \
  -H 'content-type: application/json' \
  -d '{  
    "user": {
      "username":"user1",
      "password":"user1"
    }
  }'
```

The response will be:

```
{
  "data": {
    "jwt": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJycHMiLCJleHAiOjE1Mjk3NzU0MzQsImlhdCI6MTUyNzM1NjIzNCwiaXNzIjoicnBzIiwianRpIjoiOGYzYTNkMGMtZDljMy00NTRlLWEzZWMtOWRhZDg1NTY3YTcyIiwibmJmIjoxNTI3MzU2MjMzLCJzdWIiOiIyIiwidHlwIjoiYWNjZXNzIn0.JAfG27Swg9EtHDjC2w0j9PkPYHlODd-pqz0hXYJybtZtXeHCm5NhM5AJDRit1HThHWJmDOAb1t539So6vpFXDQ",
    "exp": 1529775434
  }
}
```

In the same way you can request a token for `user2`.

### Creating a Match

The next step is create a new match game:

```
$ curl -X POST \
  http://localhost:4000/api/v1/match_games \
  -H 'authorization: Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJycHMiLCJleHAiOjE1Mjk3NzU0MzQsImlhdCI6MTUyNzM1NjIzNCwiaXNzIjoicnBzIiwianRpIjoiOGYzYTNkMGMtZDljMy00NTRlLWEzZWMtOWRhZDg1NTY3YTcyIiwibmJmIjoxNTI3MzU2MjMzLCJzdWIiOiIyIiwidHlwIjoiYWNjZXNzIn0.JAfG27Swg9EtHDjC2w0j9PkPYHlODd-pqz0hXYJybtZtXeHCm5NhM5AJDRit1HThHWJmDOAb1t539So6vpFXDQ' \
  -d '{}'
```

The response:

```
{
  "data": {
    "winner": null,
    "status": "created",
    "player2_wins": 0,
    "player2_id": null,
    "player1_wins": 0,
    "player1_id": 2,
    "match_rounds": [],
    "id": 1
  }
}
```

> **NOTE:** The user that created the match is set as a `player1` automatically;
  it doesn't make sense to create a game for two players different than who has
  created the game.

### Join to an existing game

Once the game or match is created, the one who created the game is waiting to
other player to join the game. So, assuming you have a token for `user2`:

```
$ curl -X PUT \
  http://localhost:4000/api/v1/match_games/1 \
  -H 'authorization: Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJycHMiLCJleHAiOjE1Mjk3NzY1NzAsImlhdCI6MTUyNzM1NzM3MCwiaXNzIjoicnBzIiwianRpIjoiZmZiNGRlOTQtZWM5YS00OWJkLTg4ZDQtYWRlNDZhODFmZjRmIiwibmJmIjoxNTI3MzU3MzY5LCJzdWIiOiIzIiwidHlwIjoiYWNjZXNzIn0.5crnWPypWq5izgzRX2y2hsFVVvy5zcNM5fJO1jPwEE8J-aa3uH5CY1rkWl-aDkZcJxKWhS51EQzrkKWhWZAwSQ' \
  -d '{}'
```

Result:

```
{
  "data": {
    "winner": null,
    "status": "started",
    "player2_wins": 0,
    "player2_id": 3,
    "player1_wins": 0,
    "player1_id": 2,
    "match_rounds": [],
    "id": 1
  }
}
```

### Play

Once second player is joined to the game, they can play, do their moves.
For example, to play `rock`:

```
$ curl -X PUT \
  http://localhost:4000/api/v1/match_games/1/match_rounds \
  -H 'authorization: Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJycHMiLCJleHAiOjE1Mjk3NzY1NzAsImlhdCI6MTUyNzM1NzM3MCwiaXNzIjoicnBzIiwianRpIjoiZmZiNGRlOTQtZWM5YS00OWJkLTg4ZDQtYWRlNDZhODFmZjRmIiwibmJmIjoxNTI3MzU3MzY5LCJzdWIiOiIzIiwidHlwIjoiYWNjZXNzIn0.5crnWPypWq5izgzRX2y2hsFVVvy5zcNM5fJO1jPwEE8J-aa3uH5CY1rkWl-aDkZcJxKWhS51EQzrkKWhWZAwSQ' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'postman-token: 7422fca2-0a27-45a9-d14b-942766550206' \
  -d '{  
    "round": {
      "move": "rock"
    }
  }'
```

Result:

```
{
  "data": {
    "move": "rock"
  }
}
```

### Getting info

It is possible also to get info about a match:

```
$ curl -X GET \
  http://localhost:4000/api/v1/match_games/1 \
  -H 'authorization: Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJycHMiLCJleHAiOjE1Mjk3NzY1NzAsImlhdCI6MTUyNzM1NzM3MCwiaXNzIjoicnBzIiwianRpIjoiZmZiNGRlOTQtZWM5YS00OWJkLTg4ZDQtYWRlNDZhODFmZjRmIiwibmJmIjoxNTI3MzU3MzY5LCJzdWIiOiIzIiwidHlwIjoiYWNjZXNzIn0.5crnWPypWq5izgzRX2y2hsFVVvy5zcNM5fJO1jPwEE8J-aa3uH5CY1rkWl-aDkZcJxKWhS51EQzrkKWhWZAwSQ'
```

Result:

```
{
  "data": {
    "id": 1,
    "winner": "player1",
    "status": "finished",
    "player2_wins": 2,
    "player2_id": 3,
    "player1_wins": 4,
    "player1_id": 2,
    "match_rounds": [
      {
        "winner": "player2",
        "player2_move": "paper",
        "player1_move": "rock",
        "num": 10
      },
      {
        "winner": "player1",
        "player2_move": "scissors",
        "player1_move": "rock",
        "num": 9
      },
      {
        "winner": "draw",
        "player2_move": "scissors",
        "player1_move": "scissors",
        "num": 8
      },
      {
        "winner": "player2",
        "player2_move": "paper",
        "player1_move": "rock",
        "num": 7
      },
      {
        "winner": "draw",
        "player2_move": "scissors",
        "player1_move": "scissors",
        "num": 6
      },
      {
        "winner": "player1",
        "player2_move": "rock",
        "player1_move": "paper",
        "num": 5
      },
      {
        "winner": "draw",
        "player2_move": "rock",
        "player1_move": "rock",
        "num": 4
      },
      {
        "winner": "player1",
        "player2_move": "scissors",
        "player1_move": "rock",
        "num": 3
      },
      {
        "winner": "draw",
        "player2_move": "scissors",
        "player1_move": "scissors",
        "num": 2
      },
      {
        "winner": "player1",
        "player2_move": "scissors",
        "player1_move": "rock",
        "num": 1
      }
    ]
  }
}
```


### Notifications

Notifications are handled via Phoenix Channels:

  * When a user creates a new match, the next step is to join to the topic
    `room:{match_id}`.
  * When the second player joins to the match, he should also join to the
    topic `room:{match_id}`.
  * Once both played are subscribed/joined to the topic `room:{match_id}`,
    both will receive notifications about the round and the match.

The server sends notifications every time a round is finished with the info
about that round (see `Rps.Games.Round` schema). And once the match is finished,
a message about the match result is sent to the players as well
(see `Rps.Games.Match`).
