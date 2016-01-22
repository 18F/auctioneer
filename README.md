# Auctioneer

A Ruby API Client for 18F's Micropurchase application.

## Requirements

- Ruby

## Installation

This is not yet a gem. Many parts are still moving, use at your own risk, etc, etc.

Clone the repo, `cd` into it, run `bundle`.

## Obtaining an API key

Go to https://github.com/settings/tokens (make sure you are logged in), and generate a Personal Access Token. Uncheck all of the "scope" options, too.

Add this key to your `.zshrc`, `.bash_profile` or similar as:

```
export MICROPURCHASE_API_KEY='your personal access token goes here'
```

## Use

Run `ruby auctioneer.rb` to access the API client inside of a `pry` session.

## Admin Methods

These methods are only available to authenticated system admins (e.g. 18F staff only).

### admin_users

```ruby
client.admin_user
#=> {...}
```

### admin_auctions

```ruby
client.admin_auctions
#=> {...}
```

### Reporting tasks

We're including in this gem methods for common data reporting/updating tasks.

#### CSV of Email addresses

```ruby
email_csv
# generates a CSV of email addresses in `emails.csv` in the root of the project
```

## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to
