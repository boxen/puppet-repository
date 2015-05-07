# Repository Type and Provider for Boxen

Requires the following boxen modules:

Supports:

* git

## Usage

```puppet
repository {
  '/path/to/code':
    source   => 'user/repo', #short hand for github repos
    provider => 'git';
  'my emacs config':
    source   => 'git://github.com/wfarr/.emacs.d.git',
    path     => '/etc/emacs.d',
    provider => 'git',
}
```

### Ensure your repo is at a specific revision

You can ensure that your repository is always at a specific revision by
including a `ensure` argument. `ensure` takes a git version.

#### In sync with remote HEAD
```puppet
repository {
  '/path/to/code':
    ensure   => 'origin/HEAD'
    source   => 'user/repo',
    provider => 'git';
  'my emacs config':
    source   => 'git://github.com/wfarr/.emacs.d.git',
    path     => '/etc/emacs.d',
    provider => 'git',
}
```

#### Specific version
```puppet
repository {
  '/path/to/code':
    ensure   => '32811db53e109197244c21a84b0fa2b36f497966'
    source   => 'user/repo',
    provider => 'git';
  'my emacs config':
    source   => 'git://github.com/wfarr/.emacs.d.git',
    path     => '/etc/emacs.d',
    provider => 'git',
}
```
