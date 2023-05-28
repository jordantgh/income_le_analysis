# Income and health in the US - dashboard

## What is this for?

In a landmark 2016 study, Raj Chetty and co-workers published one of the most comprehensive [single-nation studies of the socioeconomic determinants of life expectancy](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4866586/). This study remains one of the largest and of its kind, and contains a wealth of data of interest to anyone involved in public health. 

Our goal with this project is to make the large collection of granular data accessible to the public through a graphical dashboard. The goal is not to tell a particular story, although there are many to tell, but rather to present an intuitive interface where people curious about the factors influencing life expectancy (and their geographical distribution) can explore their own ideas.

## How to contribute

It is possible to simply clone the repo and start submitting pull requests if you are set up for it, but this project is heavy on dependencies. Thus I have provided a containerised development environment via Docker that will allow you to execute all the R code without any problems. This assumes you are working in VS code; if you want to work in RStudio or any other editor, I can't guarantee things won't break. However, rest assured that all of the VSC:R crosstalk is set up within the container. 

To get started with the container, make sure you have [Docker installed](https://docs.docker.com/) and running.

Clone the repo and open it inside VS code. You should be prompted with an option to "Reopen in Container" at the bottom right; if not, you can do it from the command palette (`Ctrl + Shift + P`) - just type "Dev Containers: " and you should see the option to open in the container. 

It will initially take a moment to download the containerised image from Docker Hub and get things set up, but you will quickly find yourself in a Debian environment with a `zsh` command prompt. The only thing left to do is check your `git` authentication. First, see if you already have access to the remote:

```
git ls-remote
```

Unless you already have SSH forwarding correctly set up, this probably won't work. From here you have a few choices. 

- For SSH agent forwarding (Linux only), make sure you have your SSH key added to the SSH agent and add `ForwardAgent yes` to the GitHub line of your ~/.ssh/config file (on your local machine, not within the container)
- You may copy the keys from your local machine directly into the ~/.ssh/ dir of the container
- You can use the GitHub CLI client (`gh`) to create new keys *in situ* for the container - use `gh auth login` and you will be prompted to authenticate with GitHub and given the option to create new keys, which will automatically be added to your GitHub account

In all cases, make sure the keys are read only (if not, use `chmod 400 </path/to/key>`) - you will not be able to push or pull commits without this. Finally, you need to add `IdentityFile /path/to/private/key` to the GitHub line of your ~/.ssh/config file.