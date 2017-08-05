# elm-hapi

Configure and run a Hapi server through an Elm effect module. **Does not support the full Hapi API**.

## Try it real quick

```bash
# Install repo
git clone https://github.com/nomalab/elm-hapi.git
cd elm-hapi
# Install node and elm packages
yarn install
yarn deps
# Build all example servers
yarn build
# Start simple server which will just display all incoming request properties as HTML
yarn start Simple
# Start complex server which will do way more stuff
yarn start Complex
# (replace "yarn" with "npm run" if you are using NPM)
```

Then open [http://localhost:8080/](http://localhost:8080/) and enjoy!

## Warning

**Never** try to call `toString` or `Debug.log` on opaque types like `Server`, `Replier`, `Handler` or `Plugin` (or any record or type containing them). Those are internal JavaScript objects which might be recursive so this will crash at runtime with a stack overflow since the Elm runtime does not handle recursive stuff like Node inspect will.

## Usage

**Requires Node 6.4.0 or later**

**Version 0.0.x, not production ready yet**

### JavaScript dependencies

Create `package.json` and add required dependencies. Should be something like:

```json
{
  "dependencies": {
    "hapi": "16.5.2"
  },
  "devDependencies": {
    "elm": "0.18.0",
    "elm-github-install": "1.1.0"
  }
}
```

If you are wondering why we need `elm-github-install`, that's because this package is an effect module using Native code, two reasons preventing us from publishing it on the Elm registry, so you will have to install it directly from GitHub.

You can change to another version of **Hapi** but we cannot guarantee that the API will be compatible with the Elm interface. Any minor or patch release should be fine but try to keep the same major version (here `16`).

### Elm dependencies

Create `elm-package.json` and do the same with Elm dependencies (don't forget to replace `ref` depending on which version you want to use):

```json
{
  "version": "1.0.0",
  "source-directories": [
    "src"
  ],
  "exposed-modules": [],
  "native-modules": false,
  "dependencies": {
    "elm-lang/core": "5.0.0 <= v < 6.0.0",
    "nomalab/elm-hapi": "1.0.0 <= v < 2.0.0"
  },
  "dependency-sources": {
    "nomalab/elm-hapi": {
      "url": "git@github.com:nomalab/elm-hapi.git",
      "ref": "<a commit number or tag name you want to install>"
    }
  },
  "elm-version": "0.18.0 <= v < 0.19.0"
}
```

### Scripts

Skip this part if you prefer do it by hand, but you might consider adding a few scripts inside `package.json`

```json
{
  "scripts": {
    "deps": "elm-github-install",
    "build": "elm-make ./src/Server.elm --output ./dist/Server.js",
    "start": "node ./index.js"
  }
}
```

### Runner

Create `index.js` which will import the generated JavaScript file from our Elm code and run it. The `require` should match the `output` of the `build` script.

```javascript
'use strict'

require('./dist/Server.js').Server.worker()
```

### Server

Ok, this is where the real work starts. You will have to create a `src/Server.elm` file and code... you know... a server. That's what we want at the end of the day after all. Checkout [SimpleServer.elm](https://github.com/nomalab/elm-hapi/blob/master/examples/SimpleServer.elm) from the examples to see the bare minimum expected code to create and start a server.

The file path should match the input of the `build` script.

### Install everything

Using our awesome scripts, we will install all dependencies

```bash
yarn install
yarn deps
```

### Build and start server

The last step. We will just build the Elm code and run it from JavaScript.

```bash
yarn build
yarn start
```

## License

TODO
