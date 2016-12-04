#ft_42

Useful 42 info from your command line.

## Setup

Note: Look for me in the lab if you have any questions.

1. Create your own 42 application
	- Go to: https://profile.intra.42.fr/oauth/applications/new
	- You just need a name and a redirect_uri. You may use the following:
		- Name: ft_42 [YOUR_42_USERNAME]
		- Redirect_URI: https://ft42.us

2. Place your app's UID and SECRET keys in your local environment by opening your ~/.bash_profile (~./zshrc if using zsh) and adding the following code:

	```shell
	export PATH=$HOME/.gem/ruby/2.0.0/bin:$PATH
	export FT42_UID=[YOUR_UID_HERE]
	export FT42_SECRET=[YOUR_SECRET_HERE]
	```

3. Reload your bash profile by running `source ~/.bash_profile` or `zsh` if you're using zsh.

4. Then run `gem install --user-install ft_42`

## Usage

Once you have it set up, you can use it like this:

```shell
# shows user info
ft_42 [42_USERNAME]
# shows user info with picture (only iTerm, only Fremont)
ft_42 [42_USERNAME] pic
# shows user info with progress bars
ft_42 [42_USERNAME] progress
```
![User Example](/example_images/user_example_regular.png?raw=true "User Example")

```shell
# shows user sessions this week, starting last monday.
ft_42 [42_USERNAME] sessions
```

![Sessions Example](/example_images/sessions_example.png?raw=true "Sessions Example")

```shell
# shows user sessions, starting 3 weeks ago
ft_42 [42_USERNAME] sessions 3 weeks ago
ft_42 [42_USERNAME] sessions 3
```

![Sessions Weeks Example](/example_images/sessions_weeks_example.png?raw=true "Sessions Weeks Example")

```shell
# shows all users currently working on project ("status = in_progress")
ft_42 project fract-ol in fremont
ft_42 project ft_ls in paris
```

![Project Users Example](/example_images/currently_working_on.png?raw=true "Project Users Example")

```shell
# you can also filter by date subscribed range
ft_42 project wolf3d in fremont after November 1, 2016
ft_42 project wolf3d in fremont between November 1, 2016 and November 20, 2016
```

![Project Users After Example](/example_images/working_on_after_paris.png?raw=true "Project Users After Example")
![Project Users Range Example](/example_images/working_on_range.png?raw=true "Project Users Range Example")

## Keep it up to date

Make sure you have the latest version by running `gem update --user-install ft_42`

## Contribute :heart:

There's lots of ways you can contribute. Hit me up on slack, fork it, play around with the implementation, or improve the docs.

You could also grab something from the todo list.

To-do List:

- Use the much cleaner `gem fortytwo` for making requests. ft_42_cli should only contain the printers.
- Improve option parser. Possibly using OptionParser tool.
- Add usage help for `ft_42` and `ft_42 help`.
- Make configuration file to improve installation process and save certain values.
