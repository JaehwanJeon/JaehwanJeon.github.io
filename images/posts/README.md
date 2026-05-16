# Blog post images

One folder per post, named exactly like the post's `_posts/*.md` file (its slug).
This keeps each post's images grouped and avoids filename collisions.

```
images/posts/2026-05-01-postdoc-uoft/cover.jpg   # header image + list thumbnail
images/posts/2026-05-01-postdoc-uoft/fig1.png    # inline figure(s)
```

Reference from the post's front matter (a commented `header:` block is already
pre-written in each _posts/*.md — just drop files here and uncomment):

```yaml
header:
  image:  /images/posts/<post-slug>/cover.jpg
  teaser: /images/posts/<post-slug>/cover.jpg
```

Inline in the post body: `![caption](/images/posts/<post-slug>/fig1.png)`

When adding a new post, create a matching folder here with the same slug.
