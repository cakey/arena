## setup
    # 1. Install node
    npm i -g gulp nodemon coffee-script
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

Note: fabric requires cairo, install using brew (make sure you overwrite links otherwise the versions mess up)