# spec-mapper
A short script to help you identify and correct misplaced specs in a rails app

# usage
Run the script with `ruby spec_mapper.rb`. This will will produce some output regarding the state of spec files in your repo and ultimately move all
the files it can. Recommended to do within a git repository so changes can be reviewed and easily undone.

Alternatively, pass the dump argument `ruby spec_mapper.rb dump` to do a test run where it will produce a `spec_paths.json` file you can review.
