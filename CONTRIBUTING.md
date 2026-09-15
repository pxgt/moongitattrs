# Contributing

Bug reports and focused pull requests are welcome. Please include the smallest
`.gitattributes` example that reproduces the behavior and, when relevant, the
output of `git check-attr`.

Before submitting a change, run:

```bash
moon fmt
moon info --target all
moon check --target all --deny-warn --warn-list +73
moon test --target all --deny-warn --warn-list +73
```

Keep the portable rule engine free of file-system and process dependencies.
Behavior changes should include black-box tests and cite the relevant Git
documentation rather than copying implementation code.
