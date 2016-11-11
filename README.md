#ft_42

Useful 42 info from your command line.

## Setup

1. Create your own 42 application
	- Go to: https://profile.intra.42.fr/oauth/applications/new
	- You just need a name and a redirect_uri. You may use the following:
		- Name: ft_42 [YOUR_42_USERNAME]
		- Redirect_URI: https://ft42.us

2. Place your app's UID and SECRET keys in your local environment by opening your ~/.bash_profile (~./zshrc if using zsh) and adding the following code:

	```shell
	export PATH=/nfs/2016/[FIRST_LETTER_OF_42_USERNAME]/[YOUR_42_USERNAME]/.gem/ruby/2.0.0/bin:$PATH
	export FT42_UID=[YOUR_UID_HERE]
	export FT42_SECRET=[YOUR_SECRET_HERE]
	```

3. Reload your bash profile by running `source ~/.bash_profile` or `zsh` if you're using zsh.

4. Then run `gem install --user-install ft_42`

## Usage

Once you have it set up, you can use it like this:

```shell
ft_42 [42_USERNAME]
```

## Keep it up to date

Make sure you have the latest version by running `gem update --user-install ft_42`
