# DOMIoT Project Structure

After kickstart script finishes installing, this directory contains the complete DOMIoT (Document Object Model for IoT) for Node.js and the drivers to test code in linux.

## drivers/linux/

**Repository**: [domiot-io/drivers](https://github.com/domiot-io/drivers.git)

Contains hardware drivers for IoT systems, including simulation drivers for testing and integration.

**Available drivers for testing:**
- `ihubx24-sim`: Input Hub x24 digital input channels simulator.
- `ohubx24-sim`: Output Hub x24 digital output channels simulator.  
- `iohubx24-sim`: I/O Hub x24 digital input/output channels simulator.
- `lcd-sim`: LCD text display simulator.

Each driver has its own subdirectory with Makefile for building.

To build load and unload a driver do:
```
make
make load # driver should now be in /dev/
make unload
```

Each driver has its own subdirectory with a README.md file with more detailed information.

## jsdomiot/

**Repository**: [domiot-io/jsdomiot](https://github.com/domiot-io/jsdomiot.git)

This directory contains the jsdomiot library as well as examples inside the `jsdomiot/examples` directory.

The DOMIoT library that extends jsdom to support IoT elements and hardware bindings. You can describe your physical world system using custom HTML IoT elements such as `<iot-button>`, `<iot-shelving-unit>`, `<iot-aisle>`, etc.

DOMIoT allows you to interact with physical IoT devices using familiar standard DOM API methods used in web development such as `getElementById`, `setAttribute` and `addEventListener`.

## Examples and How to Run Them

Inside each example directory there is a README.md file with specific instructions.

```
`cd jsdomiot/examples/0-retail-buttons-shelving-units`
node main.mjs
```

Navigate to the examples directory to see all available examples:
```
cd jsdomiot/examples/
ls -la
```

## Understanding the Architecture

### DOMIoT Components

1. **Drivers**: Enable communication with physical I/O components.
   - Located in the `drivers/` directory
   - "-sim" suffixed drivers are simulation drivers for testing without hardware.
   - Find more: [drivers](https://github.com/domiot-io/drivers)

2. **Elements**: Domain-specific HTML elements for real-world objects (`<iot-room>`, `<iot-door>`, `<iot-button>`, `<iot-shelving-unit>`, ...).
   - Find more: [iot-elements-node](https://github.com/domiot-io/iot-elements-node)

3. **Bindings** - Connect virtual DOM elements to physical hardware through devices.
   - Find more: [iot-bindings-node](https://github.com/domiot-io/iot-bindings-node)


The elements and bindings packages include collections of element and binding factories.

## Learn More

- **Website**: [domiot.org](https://domiot.org)
- **Repositories**: [domiot-io repositories](https://github.com/domiot-io/)
