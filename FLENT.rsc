###
###  Installer for "FLENT" 
###
:put "** Loading \$FLENT"


:global FLENT
:set FLENT do={
    :global FLENT 
    :local arg1 $1
    :local arg2 $2
    :local action 0
    :local lpath
    :local lbranch

    :if ([:typeof $arg1]="str") do={
        :set action $arg1
    }
    :if ([:typeof $path]="str") do={
        :set lpath $path
        :put "setting path=$path"
    }
    :if ([:typeof $branch]="str") do={
        :set lbranch $branch
    }

    ## MAIN SETTINGS FOR CONTAINER

    # name of container, used in comment to find - could be multiple so add a "containername1[2,...]" to things 
    :local ocipkg "flent"
    :local ocipushuser "tikoci"
    :local containerregistry "ghcr.io"
    :local scripthelpername "FLENT"
    :local containernum "1" 
    :local containeripbase "198.19.102."
    :local containerprefix "24"
    :local containerver "main"
    :local containerbootatstart "yes"
    :local containeraddresslist "LAN"
    :local containerhostip "254"
    :local containerbridge ""
    :local containerlogging "yes"
    :local containerenvs [:toarray ""]
    :local maxwaitforstart "3m"
    :set ($containerenvs->"TEST") "rrul"
    :set ($containerenvs->"SERVER") "198.18.18.18"
    :set ($containerenvs->"DURATION") "60"
    :set ($containerenvs->"PLOT") "all_scaled"
    :set ($containerenvs->"PORT") "12865"
    :set ($containerenvs->"OPT1") "-z"
    :set ($containerenvs->"OPT2") "-v"
 
    :local containermounts [:toarray ""]
    :set ($containermounts->"data") "/data"
 
    # TODO figure out where files go...

    # container specific variables
    :local netserverport ($containerenvs->"PORT")

    :if ([:typeof $hostid]~"str|num") do={
        :set containernum $hostid
    }

    # calculate name and tag (do not change these)
    :local containername "$ocipkg" 
    :local containertag "$containername$containernum"
    :local ociprojsrcroot "https://raw.githubusercontent.com/$(ocipushuser)/$(containername)/$containerver"

    # RouterOS IP config
    :local containerethname "veth-$containertag"
    :local containerip "$containeripbase$containernum"
    :local containergw "$($containeripbase)254"

    # path= option
    :local rootdisk ""
    :if ([:typeof $lpath]="str") do={
        :set rootdisk $lpath
    } else={
        :set rootdisk "nfs1"
    }
    :local rootpath "$rootdisk/$containertag"
    #:put "using disk path prefix of $rootpath, use path= option to change"

    # branch= option
    :if ([:typeof $branch]="str") do={
        :set containerver $branch
    } 

    :if ($dump = "yes") do={
        :put "FLENT dump (as calculated, any existing container settings rule)"
        :put "     branch (ARG)           =   $branch                   "
        :put "     force (ARG)            =   $force                    "
        :put "     path (ARG)             =   $path                     "
        :put "     url (ARG)              =   $url                      "
        :put "     rootpath               =   $rootpath                  "
        :put "     ocipkg                 =   $ocipkg                    "
        :put "     ocipushuser            =   $ocipushuser               "
        :put "     ociprojsrcroot         =   $ociprojsrcroot            "        
        :put "     containerregistry      =   $containerregistry         "      
        :put "     scripthelpername       =   $scripthelpername          "     
        :put "     containernum           =   $containernum              " 
        :put "     containeripbase        =   $containeripbase           "    
        :put "     containerprefix        =   $containerprefix           "    
        :put "     containerver           =   $containerver              " 
        :put "     containerbootatstart   =   $containerbootatstart      "         
        :put "     containeraddresslist   =   $containeraddresslist      "         
        :put "     containerhostip        =   $containerhostip           "       
        :put "     containerbridge        =   $containerbridge           "    
        :put "     containerenvs          =   $containerenvs             "  
        :put "     containermounts        =   $containermounts           "    
        :put "     containerethname       =   $containerethname          "     
        :put "     containerip            =   $containerip               "
        :put "     containergw            =   $containergw               "
        :put "     rootdisk               =   $rootdisk                  "
        :put "     rootpath               =   $rootpath                  "
    }

    :local REGISTRY do={
        /container/config {
            :local curregurl [get registry-url]
            :if ([:typeof $url]="str") do={
                :put "registry set to provided url: $url"
                set registry-url=$url 
                /;
                :return $curregurl 
            }
            :if ([:typeof $arg2]="str") do={ 
                :if ($arg2~"github|ghcr") do={
                    set registry-url="https://ghcr.io"
                    :put "registry updated from $curregurl to GitHub Container Store (ghcs.io)"
                    /;
                    :return $curregurl
                }
                :if ($arg2~"docker") do={
                    set registry-url="https://registry-1.docker.io"
                    :put "registry updated from $curregurl to Docker Hub"
                    /;
                    :return $curregurl
                } else={
                    :error "setting invalid or unknown registry - failing"
                }
            } else={
                :put "current container registry is: $curregurl"
                /;
                :return $curregurl
            }
        }
        :error "unhandled path in \$FLENT registry - should return something"
    }

    # "$FLENT make" - removes any existing and install new container
    :if ($action = "make") do={

        ## WARN BEFORE CONTINUE
        :put "continuing will install $containertag and modify configuration"
        :put "...starting in 5 seconds - hit ctrl-c now to STOP"
        :delay 5s

        # add veth
        /interface/veth {
            :put "check veth"
            :local veth [add name="$containerethname" address="$containerip/$containerprefix" gateway=$containergw comment="#$containertag"]
            :put "added VETH - $containerethname address=$(containerip)/$(containerprefix) gateway=$containergw "
        }

        # envs= option
        /container/envs {
            :put "check envs"
            add name="_$containername" key="lasttag" value=$containertag
            :foreach k,v in=$containerenvs do={
                :put "setting $containertag env $k to $v"
                add name="$containertag" key="$k" value=$v comment="#$containertag"
            }
        }
        # mounts= option
        /container/mounts {
            :put "check mounts"
            :foreach k,v in=$containermounts do={
                :put "setting $containertag env $k to $v"
                add name="$containertag-$k" src="$rootpath-$[:tostr $k]" dst="$[:tostr $v]" comment="#$containertag"
            }
        }

        # add ip address to routeros
        /ip/address {
            :put "check hostip"
            :if ([:typeof [:tonum $containerhostip]] = "num") do={
                :local ipaddr [add interface="$containerethname" address="$(containergw)/$(containerprefix)" comment="#$containertag"]
                :put "added IP address=$(containergw)/$(containerprefix) interface=$containerethname"
            }
        }

        # TODO handle bridge!=""

        /interface/list/member {
            :if ([:len $containeraddresslist] > 0) do={
                :local iflistmem [add interface="$containerethname" list="$containeraddresslist" comment="#$containertag"]
                :put "added $containerethname to $containeraddresslist interface list"
            }
        }

        # TODO figure out if any are needed?
        /ip/firewall/nat {}
        /ip/firewall/filter {}
        /ip/route {}

        /container {
            :local containerid
            # tarfile= option
            :if ([:typeof $tarfile]="str") do={
                :put "adding new $containertag container on $containerethname using $(rootdisk)/$(containername).tar"
                :set containerid [add file="$tarfile" interface="$containerethname" logging=$containerlogging root-dir="$(rootpath)-root"]
            } else={
                :local lastreg [$REGISTRY github]
                # TODO handle no building paths here if options messing
                :local containerpulltag "$(containerregistry)/$(ocipushuser)/$(containername):$(containerver)"
                :put "pulling new $containertag container on $containerethname using $containerpulltag"
                :set containerid [add remote-image="$containerpulltag" interface="$containerethname" logging=$containerlogging root-dir="$(rootpath)-root"]
                [$REGISTRY url=$lastreg]
            }
            :put "setting comment #$containertag"
            set $containerid comment="#$containertag"
            :put "setting start-on-boot $containerbootatstart"

            :local lmountstr [mount find comment~"#$containertag"]
            :local lmountstrlen [:len $lmountstr]
            :put "setting $lmountstrlen mounts $[:tostr $lmountstr]"
            :if ($lmountstrlen > 0) do={
                set $containerid mounts=$lmountstr
            }

            :put "setting any envs"
            :if [/container/envs find name="$containertag"] do={
                :put "setting env tag tp $containertag"
                set $containerid env="$containertag" 
            }

            :put "make done, sending start"
            [$FLENT start hostid=$containernum]
        }
        / {
            :put "** done"
        }
        :return ""
    }


    :if ($action = "start") do={
        /container {
            :local waitstart [:timestamp]
            :local startrequested 0
            :local containerid [find comment~"#$containertag"]
            :while ([get $containerid status]!="running") do={
                :put "$containertag is $[get $containerid status]";
                :if ([get $containerid status] = "error") do={
                    :error "opps! some error importing container"
                }
                :delay 3s
                :if ([get $containerid status] = "stopped" && $startrequested = 0) do={
                    :put "$containertag sending start";
                    :do { 
                        start $containerid;
                        :set startrequested 1
                    } on-error={}
                    
                }
                :delay 7s
                :if ( [:timestamp] > ($waitstart+[:totime $maxwaitforstart]) ) do={
                    /log print proplist=
                    :put "opps. took too long..."
                    :put "dumping logs..."
                    /log print proplist=message where topics~"container"
                    :error "opps. timeout while waiting for start.  check logs above for clues and retry build."
                }
            }
            :if ([get $containerid status] = "running") do={
                :put "$containertag started"
            } else={
                :error "$containertag failed to start"
            }
        }
        / {
            :return ""
        }
    }

    

    :if ($action = "stop") do={
        /container {
            :local activeid [find comment~"#$containertag"]
            #:local activecontainer [get $activeid ]
            :foreach containerinstance in=$activeid do={
                :put "$containertag found existing container to stop..."            
                :while (!([get $containerinstance status]~"stopped|error")) do={
                    :do { stop $containerinstance } on-error={}
                    :delay 5s
                    :put "$containerinstance awaiting waiting stop..."
                }
            }
        }
        :return ""
    }

    :if ($action = "clean") do={
        /container {
            :put "$containertag removing any existing container..."            
            :local containerexisting [find comment~"#$containertag"]
            :if ([:len $containerexisting] > 0) do={
                $FLENT stop
                :delay 1s
                remove $containerexisting
                :put "old container $containerinstance stopped and removed"
            } else={
                :put "no existing container found to remove"
            }
        } 
        /interface/veth {
            :local rveth [remove [find comment~"#$containertag"]]
            :put "$containertag removing veth $rveth"
        }
        /ip/address {
            :local ripaddr [remove [find comment~"#$containertag"]]
            :put "$containertag removing ip address from router $ripaddr"
        }
        /container/envs {
            :local renvs [remove [find comment~"#$containertag"]]
            :put "$containertag removing envs $renvs"
        }
        /container/mounts {
            :local rmounts [remove [find comment~"#$containertag"]]
            :put "$containertag removing mounts $rmounts"
        }
        /interface/list/member {
            remove [find comment~"$containertag"]
            :put "$containertag removing from interface list"
        }
        /ip/firewall/nat {
            :local rdstnats [remove [find comment~"#$containertag"]]
            :put "$containertag removing dst-nats $rdstnats"
        }
        /ip/firewall/filter {}
        /ip/route {}

        / {
            :put "$containertag $containerinstance clean done"
            :return ""
        }
    }

    :if ($action = "shell") do={
        /container {
            :local activeid [find comment~"#$containertag"]
            :if ([:len $activeid] = 0) do={
                :local activename [/container/envs get [/container/envs find name="_$containername" key="lasttag"] value]
                :set activeid [find comment~"#$activename"]
            }
            :if ([:len $activeid] < 1) do={
                :error "$containertag could not find the container, shell is not possible"
            }
            :if ([get $activeid "status"] != "running") do={
                :put "container is not running. force=$force"
                $FLENT stop
                :local oldcmd [get $activeid cmd]
                :if ([:tostr $force] = "yes") do={
                    :put "saving old cmd $oldcmd"
                    set $activeid cmd="tail -f /dev/null"
                    :put "attempting start with force=$force with 'tail'"
                    $FLENT start
                    :put "started, connected without builtin cmd"
                    :do { shell $activeid } on-error={}
                    :put "back from shell, resetting $oldcmd"
                    set $activeid cmd=$oldcmd
                    :return ""
                } else={
                    :put "container is not running, starting for shell"
                    $FLENT start
                }
            } 
            :put "starting shell"
            :do { shell $activeid } on-error={}
            :put "back from shell"
        }
        :return ""
    }

    :if ($action = "log") do={
        /log print where topics~"container" and time>([/system clock get time] - 2m)
        :return ""
    }
    
    :if ($action = "tail") do={
        /log print follow where topics~"container" and time>([/system clock get time] - 2m)
        :return ""
    }
    :put  "Usage: \$$(scripthelpername) make|clean|shell|dump|start|stop|registry "
    :error "Bad Command: see docs at https://github.com/$(ocipushuser)/$(containername)"
}


# Some examples:

# To build:
# $FLENT clean
# $FLENT make [path=<disk_prefix>] [branch=<tagver>] [hostid=<num=1>] [dump=yes]

# To control/manage
# $FLENT stop
# $FLENT start
# $FLENT shell force=["no"|"yes"]

# Helper to switch between DockerHub and GitHub Container Registry
# $FLENT registry
# $FLENT registry <github|docker> [url=<str>]

$FLENT dump=yes



