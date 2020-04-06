# CodeGen.Graph

---

# Reference

This module produces the call tree between chunks of a template.

It is useful to find orphan chunk.

## Functions

### to_dot( tmpl )

Returns a string in
[DOT](http://graphviz.org/content/dot-language) format.

# Examples

```sh
$ lua -e "print(require 'CodeGen.Graph'.to_dot(require 'CodeGen.Graph'.template))" > graph.dot
$ dot -T png -o graph.png graph.dot
```

```sh
$ cat graph.dot
digraph {
    node [ shape = none ];

    _node;
    TOP;
    _edge;

    TOP -> _node;
    TOP -> _edge;
}
```

![graph.png](img/graph.png)
