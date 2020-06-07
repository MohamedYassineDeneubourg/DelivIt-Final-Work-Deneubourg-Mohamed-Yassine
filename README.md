DelivIt is a mobile application that is going to help people to do their shopping and delivery by other people. This is community-based application where anyone can become a buyer or deliverer.
# Getting Started

First of all you need to install Flutter on your machine.
[Check the documentation of Flutter to achieve this.](https://flutter.dev/docs).

After the installing, open the project in an compatible IDE. We recommand you to use **Visual Studio Code** or **Android Studio.**
You can now run the follow command to install all the necessary packages.

```
$ flutter pub get
```
This needs to be runned with a terminal in the project-folder.

# Run the DelivIt application 

 First run the following command.
```
$ flutter doctor
```
Ensure everything is installed correctly.
### Emulators (iOS & Android)
> To run on iOS, you need Xcode on macOS.

Before running you need to have at least one active device connected to your machine.
You can run the following command to get a list of all connected devices.
```
$ flutter devices
```
You can only run the application when a device is connected. To achieve this run the following command.
```
$ flutter run
```
This will take the first device in the list. 
### Multiple Emulators
It is possible to run the application simultaneously in multiple devices.
Run the following command.
```
$ flutter run -d all
```
This will run the application on all the connected devices that can be found in **flutter devices**

# Problems to run
If you have any problem to run the application, please clean the build-files with the following command.
```
$ flutter clean
```