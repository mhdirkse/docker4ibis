# Use the IAF docker image to develop Ibis Configurations

In this manual we will explain how you can use the IAF docker image to develop your own Ibis Configurations, without the need for a specific IDE such as Eclipse. We assume that you already have Docker Desktop installed and running on you computer, if not first install Docker Desktop.

## Building the IAF image

For the time being it is necessary for you to build the IAF image yourself. The files needed to build the IAF image can be found in the IAF_Image directory. Open up your favorite command-line-interface and go to the IAF_Image directory on your computer. First make sure you are logged in with your Docker account. Use the command:

- docker login

Now, use the following command to build the image:

- docker build -t iaf:7.5 .

Wait for the building process to finish and you should be able to use the IAF image.

## Setup your project directories

In the text file called project_directory you can give the path to the directory containing your Ibis configurations. Just change the value to the path you want. This project directory should contain one directory for every Ibis you have. The name of these directories should be the same as their corresponding Ibis.
Inside one of these directories you can give a text file called "properties" to set certain properties such as the database you want to use. A template for this properties file can be found in the Git repository. In this file you can also set a path to your **classes**, **configurations**, and **tests** folders. The **classes** folder should contain your main configuration. If you have multiple configurations for your Ibis, the other configurations should be placed in the **configurations** folder.  When doing so make sure to set the classLoaderType of these configurations to DirectoryClassLoader in a DeploymentSpecifics file in the **classes** folder. In the **tests** folder you can place your Larva test scenarios.  If you do not have any extra configurations or any Larva test scenarios you should give an empty string to the properties Ibis_Config and Ibis_Tests respectively.
It is also possible not to give a properties text file, in this case default values will be used when starting the IAF docker image. When using the default values the following directory structure is expected, given I have two Ibis configurations called Ibis4Example and Ibis4Test:

```

                                         +---------+                    +--------------------+
                            +----------->| classes |+-------contains--->| Main configuration |
                            |            +---------+                    +--------------------+
                            |
                            |         +----------------+                +----------------------+
                            |  +----->| configurations |+---contains--->| Other configurations |
                +-----------+--+      +----------------+                +----------------------+
         +----->| Ibis4Example |
         |      +-----------+--+         +---------+                    +----------------------+
         |                  |  +-------->|  tests  |+-------contains--->| Larva test scenarios |
         |                  |            +---------+                    +----------------------+
         |                  |
         |                  |         +----------------+
         |                  +-------->| properties.txt |
         |                            +----------------+
 +-------+-----------+
 | Project_Directory |
 +-------+-----------+
         |                               +---------+
         |               +-------------->| classes |
         |               |               +---------+
         |               |
         |               |            +----------------+
         |               |  +-------->| configurations |
         |      +--------+--+         +----------------+
         +----->| Ibis4Test |
                +--------+--+            +---------+
                         |  +----------->|  tests  |
                         |               +---------+
                         |
                         |            +----------------+
                         +----------->| properties.txt |
                                      +----------------+
```
Right now, the supported databases are Mssql Server, Postgresql and H2. In order to use these databases give "mssql", "postgresql" or "h2" as the Database property in the "properties" text file of your Ibis. It is important to give these exact strings. The default database used is H2.

## Starting the docker container

When everything is set up correctly you can easily start a docker container by executing either the "iaf_startup.bat" script (Windows) or the "iaf_startup.sh" script (Linux). You should also give the name of the Ibis you want to start as a parameter to the script. So for instance, if I want to start my Ibis4Example configuration on Windows I use:

- .\iaf_startup.bat Ibis4Example

After the tomcat server has fully started, you can go to localhost:(**hostport**)/(**ibisname**) to open the console.
Here the **hostport** is the port that was specified in the "properties" file of your Ibis, with default port 80, and the **ibisname** is the name of your Ibis, in all lowercase letters.

## Checking on your containers

You can see all your running containers using the docker command:

- docker ps
 
If you also want to see all existing containers you can use:

- docker ps -a

If you want to stop a running container use:

- docker stop (**containername**)

And you can remove a container with:

- docker rm (**containername**)
