# Werewolf Narrator

A companion application designed to assist the narrator in managing and running a game of Werewolf efficiently.

## Development

This project uses [`just`](https://github.com/casey/just) as a command runner to simplify common workflows.

To view all available commands:
```sh
just
```

To run the application in a development environment:
```sh
just run [DEVICE]
```
where `[DEVICE]` is a valid target device. To list available devices, run:
```
flutter devices
```

## Building

The project supports building for multiple platforms and configurations.

To list all available build commands:

```sh
just --list --group=build
```

To execute a build, run the desired command. For example:

```sh
just build-split-apk --flavor=staging
```

## Contributing

Contributions are welcome and appreciated.

This includes, but is not limited to:
- Improvements to general application behavior or usability
- Bug fixes
- Implementation of additional game roles

Feel free to open an issue to discuss ideas, even if you don't know how to implement them, or submit a pull request directly.