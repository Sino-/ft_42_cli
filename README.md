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
```
![User Example](/example_images/user_example.png?raw=true "User Example")

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
# shows all users within campus subscribed to specific project
ft_42 project fract-ol in fremont
ft_42 project ft_ls in paris
```

![Project Users Example](/example_images/project_users_example.png?raw=true "Project Users Example")

## Keep it up to date

Make sure you have the latest version by running `gem update --user-install ft_42`
