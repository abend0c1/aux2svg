# CICS AUXLIARY TRACE VISUALISER

## Function

Creates a graphical representation of a CICS auxiliary
trace printout by using Scalable Vector Graphics (SVG).
The SVG markup represents the trace data in the form
of a Unified Modelling Language (UML) Sequence Diagram
(or at least something quite like it).

The *actors* (for example, programs) are listed side-by-side 
at the top of the diagram. A *life line* is
drawn vertically below each actor. Interactions
between actors (for example, calls and returns) are
represented as arrows drawn between the life lines.
The vertical axis is time. Each interaction is labeled
on the left of the diagram with the relative time in
seconds since the start of the trace and the task id.
All the interactions for a task are assigned the same
unique color. Each interaction is annotated with the
trace sequence number, to enable you to refer back to
the original trace record for more detail, and a summ-
ary of the call and return values. Exception responses
are shown in red.

You can choose which actors you are interested in by
specifying one or more CICS domain names. For example, if
you wanted to visualize TCP/IP socket activity, you
would specify the PG (Program) and SO (Socket) domains:

    aux2svg mytrace.txt (PG SO

If you wanted to examine a storage allocation problem
you could specify the SM (Storage Manager) domain:

    aux2svg mytrace.txt (SM

By default, ALL domains are selected but this can take
a long time to process. It is best to restrict the
actors to a few domains that you are interested in.


## Usage

You can run this Rexx under IBM z/OS using TSO Rexx, or under Linux
or Windows using Regina Rexx from:

   http://regina-rexx.sourceforge.net

If you run aux2svg under z/OS, then it will create
either output datasets or PDS members depending on
whether the input auxliary trace print file is in
a sequential dataset or a partioned dataset.

For an input sequential dataset "dsn", the following
files will be created:

    dsn.HTML  <-- Unless you specified the NOHTML option
    dsn.XML   <-- If you specified the XML option

For an input PDS member "dsn(mem)", the following
members will be created:

    dsn(memH) <-- Unless you specified the NOHTML option
    dsn(memX) <-- If you specified the XML option

You should restrict the length of the member name to
no more than 7 characters to accommodate the H or X
suffix.

You should then download the resulting html file to a
PC by:

    ftp yourmainframe
    youruserid
    yourpassword
    quote site sbdataconn=(IBM-1047,ISO8859-1)
    get 'your.output.html' your.output.html

However, it is probably quicker to download the CICS
auxiliary trace print file to you PC and process it
there by issuing:

    rexx aux2svg.rexx your.trace.txt (options...

...which will create the following files:

    your.trace.html <-- Unless you specified NOHTML
    your.trace.xml  <-- If you specified the XML option

You can view the resulting HTML file using any modern
web browser.

## Syntax

    AUX2SVG infile [(options...]

Where,

* `infile` Is the name of file to read auxtrace printout from

* `options` are:

    | Option | Meaning |
    | --- | --- |
    | HTML   | Create html file from the input (default) |
    | XML    | Create xml file from the input file |
    | EVENT  | Process input EVENT trace records (default) |
    | DATA   | Process input DATA trace records (default) |
    | DETAIL | Include hex data for each record in the xml output file |
    | xx     | One or more 2 letter domain names that you want to process. The default is ALL trace domains and can be much slower. For example, to show socket activity you would specify PG and SO |

    To negate any of the above options, prefix
    the option with NO. For example, NOXML.

## Trace Domains

The supported CICS trace domains include:
 
| Domain | Description |
| - | - |
| AP | Application Domain | 
| BA | Business Application Manager Domai
| CC | CICS Catalog Domain | 
| DD | Directory Domain | 
| DH | Document Handler Domain | 
| DM | Domain Manager Domain | 
| DP | Debugging Profiles Domain | 
| DS | Dispatcher Domain | 
| DU | Dump Domain | 
| EI | External CICS Interface over TCP/I
| EJ | Enterprise Java Domain | 
| EM | Event Manager Domain | 
| EP | Event Processing Domain | 
| EX | External CICS Interface Domain | 
| FT | Feature Domain | 
| GC | Global Catalog Domain | 
| IE | IP ECI Domain | 
| II | IIOP Domain | 
| IS | Inter-System Domain | 
| KE | Kernel Domain | 
| LC | Local Catalog Domain | 
| LD | Loader Domain | 
| LG | Log Manager Domain | 
| LM | Lock Manager Domain | 
| ME | Message Domain | 
| ML | Markup Language Domain | 
| MN | Monitoring Domain | 
| MP | Managed Platform Domain | 
| NQ | Enqueue Domain | 
| OT | Object Transaction Domain | 
| PA | Parameter Manager Domain | 
| PG | Program Manager Domain | 
| PI | Pipeline Manager Domain | 
| PT | Partner Domain | 
| RL | Resource Life-cycle Domain | 
| RM | Recovery Manager Domain | 
| RS | Region Status Domain | 
| RX | RRMS Domain | 
| RZ | Request Streams Domain | 
| SH | Scheduler Domain | 
| SJ | Java Virtual Machine Domain | 
| SM | Storage Manager Domain | 
| SO | Socket Domain | 
| ST | Statistics Domain | 
| TI | Timer Domain | 
| TR | Trace Domain | 
| TS | Temporary Storage Domain | 
| US | User Domain | 
| WB | Web Domain | 
| W2 | Web 2.0 Domain | 
| XM | Transaction Manager Domain | 
| XS | Security Manager Domain | 
