## setup
    # 1. Install node
    npm install -g gulp
    npm install -g nodemon
    npm install


## to dev (watches for file changes, and runs dev server)
	gulp
    gulp tdd # separate tab for karma tests
    nodemon -w src/server -w src/lib src/server/main.coffee # run server
## stack
 * http://sass-lang.com/guide
 * http://coffeescript.org/
 * http://jade-lang.com/
 * http://gulpjs.com/
