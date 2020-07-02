/*REXX 2.0.0

  CICS Auxiliary Trace Visualizer V2.0
  Copyright (C) 2005-2020 Andrew J. Armstrong

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

      * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in
        the documentation and/or other materials provided with the
        distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 Author:
 Andrew J. Armstrong <androidarmstrong@gmail.com>
*/

/*REXX*****************************************************************
**                                                                   **
** NAME     - AUX2SVG                                                **
**                                                                   **
** FUNCTION - Creates a graphical representation of a CICS auxiliary **
**            trace printout by using Scalable Vector Graphics (SVG).**
**            The SVG markup represents the trace data in the form   **
**            of a Unified Modelling Language (UML) Sequence Diagram **
**            (or at least something quite like it).                 **
**                                                                   **
**            The 'actors' (for example, programs) are listed side-  **
**            by-side at the top of the diagram. A life line is      **
**            drawn vertically below each actor. Interactions        **
**            between actors (for example, calls and returns) are    **
**            represented as arrows drawn between the life lines.    **
**            The vertical axis is time. Each interaction is labeled **
**            on the left of the diagram with the relative time in   **
**            seconds since the start of the trace and the task id.  **
**            All the interactions for a task are assigned the same  **
**            unique color. Each interaction is annotated with the   **
**            trace sequence number, to enable you to refer back to  **
**            the original trace record for more detail, and a summ- **
**            ary of the call and return values. Exception responses **
**            are shown in red.                                      **
**                                                                   **
**            You can choose which actors you are interested in by   **
**            specifying one or more domain names. For example, if   **
**            you wanted to visualize TCP/IP socket activity, you    **
**            would specify the PG (program) and SO (socket) domains:**
**                                                                   **
**              aux2svg mytrace.txt (PG SO                           **
**                                                                   **
**            If you wanted to examine a storage allocation problem  **
**            you would specify the SM (storage manager) domain:     **
**                                                                   **
**              aux2svg mytrace.txt (SM                              **
**                                                                   **
**            By default, ALL domains are selected but this can take **
**            a long time to process. It is best to restrict the     **
**            actors to a few domains that you are interested in.    **
**                                                                   **
**                                                                   **
** USAGE    - You can run this Rexx under IBM z/OS, or under Linux   **
**            or Windows using Regina Rexx from:                     **
**                                                                   **
**               http://regina-rexx.sourceforge.net                  **
**                                                                   **
**            If you run aux2svg under z/OS, then it will create     **
**            either output datasets or PDS members depending on     **
**            whether the input auxliary trace print file is in      **
**            a sequential dataset or a partioned dataset.           **
**                                                                   **
**            For an input sequential dataset "dsn", the following   **
**            files will be created:                                 **
**                                                                   **
**              dsn.HTML  <-- Unless you specified the NOHTML option **
**              dsn.XML   <-- If you specified the XML option        **
**                                                                   **
**            For an input PDS member "dsn(mem)", the following      **
**            members will be created:                               **
**                                                                   **
**              dsn(memH) <-- Unless you specified the NOHTML option **
**              dsn(memX) <-- If you specified the XML option        **
**                                                                   **
**              You should restrict the length of the member name to **
**              no more than 7 characters to accommodate the H or X  **
**              suffix.                                              **
**                                                                   **
**            You should then download the resulting html file to a  **
**            PC by:                                                 **
**                                                                   **
**            ftp yourmainframe                                      **
**            youruserid                                             **
**            yourpassword                                           **
**            quote site sbdataconn=(IBM-1047,ISO8859-1)             **
**            get 'your.output.html' your.output.html                **
**                                                                   **
**                                                                   **
**            However, it is probably quicker to download the CICS   **
**            auxiliary trace print file to you PC and process it    **
**            there by issuing:                                      **
**                                                                   **
**            rexx aux2svg.rexx your.trace.txt (options...           **
**                                                                   **
**            ...which will create the following files:              **
**                                                                   **
**            your.trace.html <-- Unless you specified NOHTML        **
**            your.trace.xml  <-- If you specified the XML option    **
**                                                                   **
**            You can view the resulting HTML file using any modern  **
**            web browser.                                           **
**                                                                   **
** SYNTAX   - AUX2SVG infile [(options...]                           **
**                                                                   **
**            Where,                                                 **
**                                                                   **
**            infile   = Name of file to read auxtrace printout from.**
**                                                                   **
**            options  = DETAIL - Include hex data for each record   **
**                                in the xml output file.            **
**                       HTML   - Create html file from the input.   **
**                       XML    - Create xml file from input file.   **
**                       EVENT  - Process input EVENT trace records. **
**                       DATA   - Process input DATA trace records.  **
**                       xx     - One or more 2-letter domain names  **
**                                that you want to process. The      **
**                                default is ALL trace domains and   **
**                                can be much slower. For example,   **
**                                to show socket activity you would  **
**                                specify PG and SO.                 **
**                                                                   **
**                       To negate any of the above options, prefix  **
**                       the option with NO. For example, NOXML.     **
**                                                                   **
**            The default options are:                               **
**                                                                   **
**                       HTML EVENT DATA NOXML NODETAIL              **
**                                                                   **
** LOGIC    - 1. Create an in-memory <html> document.                **
**                                                                   **
**            2. Create an in-memory <auxtrace> element, but do not  **
**               connect it to the <html> document.                  **
**                                                                   **
**            3. Scan the auxiliary trace output and convert each    **
**               pair of ENTRY/EXIT trace entries into a single XML  **
**               <trace> element. Add each <trace> element to the    **
**               <auxtrace> element and nest the <trace> elements.   **
**               The <auxtrace> element is a temporary representation**
**               of the auxiliary trace data and will be discarded   **
**               and/or written to an output file later.             **
**                                                                   **
**            4. Walk through the tree of <trace> elements and when  **
**               an interesting <trace> element is found, add        **
**               appropriate markup to the <html> element in order   **
**               to visualize the <trace> element.                   **
**                                                                   **
**            5. Output an HTML document by using the PrettyPrinter  **
**               routine to 'print' the <html> element to a file.    **
**                                                                   **
**            6. Output an XML document by using the PrettyPrinter   **
**               routine to 'print' the <auxtrace> element (only if  **
**               the XML option was specified).                      **
**                                                                   **
** EXAMPLE  - 1. To investigate a socket programming problem:        **
**                                                                   **
**               AUX2SVG auxtrace.txt (PG SO DETAIL XML              **
**                                                                   **
**               This will create the following files:               **
**                 auxtrace.html - HTML representation of the trace. **
**                 auxtrace.xml  - XML representation of the trace.  **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong@gmail.com>       **
**                                                                   **
** HISTORY  - Date     By       Reason (most recent at the top pls)  **
**            -------- -------- ------------------------------------ **
**            20200623 AJA      Support for CICS TS 5.5.             **
**                              Modernise the HTML output.           **
**            20060120 AJA      Conform to CSS2 requirements of      **
**                              Mozilla Firefox 1.5 (font-size must  **
**                              have a unit, stroke-dasharray must   **
**                              use a comma as a delimiter).         **
**            20051027 AJA      Draw colored arrow heads.            **
**            20051026 AJA      Set xml name space to 'svg' (oops!). **
**            20051025 AJA      Minor changes. Fixed bug in parsexml.**
**            20051018 AJA      Documentation corrections. Enhanced  **
**                              getDescriptionOfCall() for CC, GC,   **
**                              DS and AP domains.                   **
**            20051014 AJA      Intial version.                      **
**                                                                   **
**********************************************************************/

  parse arg sFileIn' ('sOptions')'

  numeric digits 16
  say 'AUX000I CICS Auxiliary Trace Visualizer v2.0'
  sOptions = 'NOBLANKS' translate(sOptions)
  call initParser sOptions /* DO THIS FIRST! Sets g. vars to '' */

  parse source g.0ENV .
  if g.0ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.0LINES = 0
    g.0NONRECURSIVE = 1
  end

  call setFileNames sFileIn
  call setOptions sOptions
  call Prolog

  if sFileIn = ''
  then do
    say 'Syntax:'
    say '   aux2svg infile [(options]'
    say
    say 'Where:'
    say '   infile  = CICS auxiliary trace print file'
    say
    say '   options = DETAIL - Include hex data for each record.'
    say '             XML    - Create xml file from input file.'
    say '             EVENT  - Include EVENT trace records.'
    say '             DATA   - Include DATA trace records.'
    say
    say '             To negate any of the above options, prefix'
    say '             the option with NO. For example, NOXML.'
    say
    say '             xx     - One or more 2-letter domain names'
    say '                      that you want to process. The'
    say '                      default is all trace domains and'
    say '                      can be much slower. For example,'
    say '                      to show socket activity you would'
    say '                      specify PG and SO.'
    say
    say 'Valid domain names are:'
    do i = 1 to g.0DOMAIN.0
      sDomain = g.0DOMAIN.i
      say '   'sDomain g.0DOMAIN.sDomain
    end
    exit
  end
  say 'AUX001I Scanning CICS auxiliary trace in' sFileIn


  doc = createDocument('html')
  call scanAuxTraceFile

  if g.0OPTION.DUMP
  then call _displayTree

  if g.0OPTION.XML
  then do
    call setDocType /* we don't need a doctype declaration */
    call prettyPrinter g.0FILEXML,,g.0AUXTRACE
  end

  if g.0OPTION.HTML
  then do
    call buildHTML
    call setPreserveWhitespace 1 /* to keep newlines in <desc> tags */
    g.0ESCAPETEXT = 0 /* suppress emitting entities */
    call prettyPrinter g.0FILEHTM
  end

  call Epilog
exit

/* The auxtrace input filename is supplied by the user.
The names of the XML and HTML output files are automatically
generated from the input file filename. The generated file names also
depend on the operating system. Global variables are set as follows:
g.0FILETXT = name of input text file   (e.g. auxtrace.txt)
g.0FILEHTM = name of output HTML file  (e.g. auxtrace.html)
g.0FILEXML = name of output XML file   (e.g. auxtrace.xml)
*/
setFileNames: procedure expose g.
  parse arg sFileIn
  if g.0ENV = 'TSO'
  then do
    parse var sFileIn sDataset'('sMember')'
    if sMember <> ''
    then do /* make output files members in the same PDS */
      sPrefix = strip(left(sMember,7)) /* room for a suffix char */
      sPrefix = translate(sPrefix) /* translate to upper case */
      g.0FILETXT = translate(sFileIn)
      /* squeeze the file extension into the member name...*/
      g.0FILEHTM = sDataset'('strip(left(sPrefix'HTM',8))')'
      g.0FILEXML = sDataset'('strip(left(sPrefix'XML',8))')'
    end
    else do /* make output files separate datasets */
      g.0FILETXT = translate(sFileIn)
      g.0FILEHTM = sDataset'.HTML'
      g.0FILEXML = sDataset'.XML'
    end
  end
  else do
    sFileName  = getFilenameWithoutExtension(sFileIn)
    g.0FILETXT = sFileIn
    g.0FILEHTM = sFileName'.html'
    g.0FILEXML = sFileName'.xml'
  end
return

getFilenameWithoutExtension: procedure expose g.
  parse arg sFile
  parse value reverse(sFile) with '.'sRest
return reverse(sRest)

scanAuxTraceFile: procedure expose g.
  g.0ACTOR_NODES = ''
  g.0AUXTRACE = createElement('auxtrace')
  call saveActor g.0AUXTRACE,'root'
  g.0FILEIN = openFile(g.0FILETXT)
  g.0K = 0   /* Trace entry count */
  g.0KD = 0  /* Trace entry delta since last progress message */

  sLine = getLineContaining('CICS - AUXILIARY TRACE FROM')
  parse var sLine 'CICS - AUXILIARY TRACE FROM ',
                   sDate ' - APPLID' sAppl .
  call setAttributes g.0AUXTRACE,,
       'date',sDate,,
       'appl',sAppl

  g.0ROWS = 0
  bAllDomains = words(g.0DOMAIN_FILTER) = 0
  sEntry = getFirstTraceEntry()
  parse var g.0ENTRYDATA.1 '='g.0FIRSTSEQ'=' .
  do while g.0RC = 0
    parse var sEntry sDomain xType sModule sAction sParms
    if sAction = '-' /* oddball format */
    then parse var sEntry sDomain xType sModule '-' sAction sParms
    if g.0FREQ.sDomain = ''
    then do
      g.0FREQ.sDomain = 0
      if g.0DOMAIN.sDomain = ''
      then do
        say 'AUX002W Unknown domain "'sDomain'" found in' sEntry
        call addDomain sDomain,'Unknown domain'
      end
    end
    g.0FREQ.sDomain = g.0FREQ.sDomain + 1
    if bAllDomains | wordpos(sDomain,g.0DOMAIN_FILTER) > 0
    then do
      parse var g.0ENTRYDATA.1 'TASK-'nTaskId . 'TIME-'sTime .,
                               'INTERVAL-'nInterval . '='nSeq'=' .
      if g.0TASK.nTaskId = '' /* if task is new */
      then do
        call initStack nTaskId
        e = createElement('task')
        call pushStack nTaskId,e
        g.0TASK.nTaskId = e
        call appendChild e,g.0AUXTRACE
        call setAttribute e,'taskid',nTaskId
      end
      task = g.0TASK.nTaskId

      nElapsed = getElapsed(sTime)
      select
        when sAction = 'ENTRY' then do
          g.0ROWS = g.0ROWS + 1 /* row to draw arrow on */
          sParms = strip(sParms)
          select
            when left(sParms,1) = '-' then do /* if new style parms */
              /* ENTRY - FUNCTION(xxx) yyy(xxx) ... */
              sParms = space(strip(sParms,'LEADING','-'))
              if pos('FUNCTION(',sParms) > 0
              then do
                parse var sParms 'FUNCTION('sFunction')'
                n = wordpos('FUNCTION('sFunction')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
              end
              else do
                if left(sParms,1) = '*'
                /* e.g. '** Decode of parameter list failed **' */
                then sFunction = sParms
                else parse var sParms sFunction sParms
              end
            end
            when pos('REQ(',sParms) > 0 then do /* old style parms */
              /* ENTRY function                 REQ(xxx) ... */
              parse var sParms sFixed'REQ('sParms
              sParms = 'REQ('sParms
              parse var sFixed sFunction sRest
              sParms = 'PARMS('sRest')'
            end
            otherwise do /* old style parms */
              /* ENTRY function parms                        */
              /* ENTRY FUNCTION(function) parms              */
              if pos('FUNCTION(',sParms) > 0
              then do
                parse var sParms 'FUNCTION('sFunction')'
                n = wordpos('FUNCTION('sFunction')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
              end
              else do
                parse var sParms sFunction sParms
              end
            end
          end
          parent = peekStack(nTaskId)
          e = createElement('trace')
          call appendChild e,parent
          call setAttributes e,,
               'seq',nSeq,,
               'row',g.0ROWS,,
               'elapsed',nElapsed,,
               'interval',getInterval(sTime),,
               'domain',sDomain,,
               'module','DFH'sModule,,
               'function',sFunction,,
               'taskid',nTaskId
          call setParmAttributes e,'entryparms',sParms
          if g.0OPTION.DETAIL & g.0ENTRYDATA.0 > 1
          then call appendDetail e,'on-entry'
          call pushStack nTaskId,e
          call saveActor e,'trace'
        end

        when sAction = 'EXIT' then do
          g.0ROWS = g.0ROWS + 1 /* row to draw arrow on */
          sParms = strip(sParms)
          sReason = ''
          sAbend = ''
          select
            when left(sParms,1) = '-' then do
              /* EXIT - FUNCTION(xxx) yyy(xxx) ... */
              sParms = space(strip(sParms,'LEADING','-'))
              if pos('FUNCTION(',sParms) > 0
              then do
                parse var sParms 'FUNCTION('sFunction')',
                               1 'RESPONSE('sResponse')',
                               1 'REASON('sReason')',
                               1 'ABEND_CODE('sAbend')'
                n = wordpos('FUNCTION('sFunction')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
                n = wordpos('RESPONSE('sResponse')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
              end
              else do
                if left(sParms,1) = '*'
                /* e.g. '** Decode of parameter list failed **' */
                then do
                  sFunction = ''
                  sResponse = ''
                end
                else parse var sParms sFunction sResponse sParms
                sReason   = ''
                sAbend    = ''
              end
            end
            when pos('REQ(',sParms) > 0 then do
              /* EXIT function response         REQ(xxx) ... */
              /* EXIT response                  REQ(xxx) ... */
              parse var sParms sFixed'REQ('sParms
              sParms = 'REQ('sParms
              if words(sFixed) = 1
              then do
                sFunction = ''
                sResponse = strip(sFixed)
              end
              else do
                parse var sFixed sFunction sResponse .
              end
            end
            when pos('FUNCTION(',sParms) > 0 then do
              /* EXIT FUNCTION(xxx) RESPONSE(xxx) parms ...  */
                parse var sParms 'FUNCTION('sFunction')',
                               1 'RESPONSE('sResponse')'
                n = wordpos('FUNCTION('sFunction')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
                n = wordpos('RESPONSE('sResponse')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
            end
            otherwise do
              parse var sParms sFunction sParms
            end
          end
          parent = popStack(nTaskId)
          if parent <> g.0AUXTRACE
          then do
            call setAttributes parent,,
                 'exitrow',g.0ROWS,,
                 'response',sResponse,,
                 'exitseq',nSeq
            sCompoundReason = strip(sReason sAbend)
            if sCompoundReason <> ''
            then call setAttribute parent,'reason',sCompoundReason
            call setParmAttributes parent,'exitparms',sParms
            call saveActor e,'exit'
          end
          if g.0OPTION.DETAIL & g.0ENTRYDATA.0 > 1
          then call appendDetail parent,'on-exit'
        end

        when sAction = 'EVENT' then do
          if g.0OPTION.EVENT
          then do
            g.0ROWS = g.0ROWS + 1 /* row to draw arrow on */
            sParms = space(strip(strip(sParms),'LEADING','-'))
            parse var sParms sFunction sParms
            parent = peekStack(nTaskId)
            e = createElement('event')
            call appendChild e,parent
            call setAttributes e,,
                 'seq',nSeq,,
                 'row',g.0ROWS,,
                 'elapsed',nElapsed,,
                 'interval',getInterval(sTime),,
                 'domain',sDomain,,
                 'module','DFH'sModule,,
                 'function',sFunction,,
                 'parms',sParms,,
                 'taskid',nTaskId
            if g.0OPTION.DETAIL & g.0ENTRYDATA.0 > 1
            then call appendDetail e,'detail'
            call saveActor e,'event'
          end
        end

        when sAction = 'CALL' then do
          sParms = space(strip(strip(sParms),'LEADING','-'))
          parse var sParms sFunction sParms
          parent = peekStack(nTaskId)
          e = createElement('call')
          call appendChild e,parent
          call setAttributes e,,
               'seq',nSeq,,
               'row',g.0ROWS,,
               'elapsed',nElapsed,,
               'interval',getInterval(sTime),,
               'domain',sDomain,,
               'module','DFH'sModule,,
               'function',sFunction,,
               'taskid',nTaskId
          call setParmAttributes e,'entryparms',sParms
          call saveActor e,'call'
        end

        when sAction = 'RETURN' | sAction = 'RETRN' then do
          sParms = space(strip(strip(sParms),'LEADING','-'))
          parse var sParms sFunction sParms
          parent = peekStack(nTaskId)
          e = createElement('return')
          call appendChild e,parent
          call setAttributes e,,
               'seq',nSeq,,
               'row',g.0ROWS,,
               'elapsed',nElapsed,,
               'interval',getInterval(sTime),,
               'domain',sDomain,,
               'module','DFH'sModule,,
               'function',sFunction,,
               'taskid',nTaskId
          call setParmAttributes e,'exitparms',sParms
          call saveActor e,'return'
        end

        when sAction = '*EXC*' then do
          g.0ROWS = g.0ROWS + 1 /* row to draw arrow on */
          sParms = space(strip(sParms,'LEADING','-'))
          parse var sParms sFunction sParms
          parent = peekStack(nTaskId)
          e = createElement('exception')
          call appendChild e,parent
          call setAttributes e,,
               'seq',nSeq,,
               'row',g.0ROWS,,
               'elapsed',nElapsed,,
               'interval',getInterval(sTime),,
               'domain',sDomain,,
               'module','DFH'sModule,,
               'function',sFunction,,
               'parms',sParms,,
               'taskid',nTaskId
          call saveActor e,'exception'
        end

        when sAction = 'DATA' then do
          if g.0OPTION.DATA
          then do
            g.0ROWS = g.0ROWS + 1 /* row to draw arrow on */
            sParms = space(strip(strip(sParms),'LEADING','-'))
            parse var sParms sFunction sParms
            parent = peekStack(nTaskId)
            e = createElement('data')
            call appendChild e,parent
            call setAttributes e,,
                 'seq',nSeq,,
                 'row',g.0ROWS,,
                 'elapsed',nElapsed,,
                 'interval',getInterval(sTime),,
                 'domain',sDomain,,
                 'module','DFH'sModule,,
                 'function',sFunction,,
                 'taskid',nTaskId
            if g.0OPTION.DETAIL & g.0ENTRYDATA.0 > 1
            then call appendDetail e,'detail'
            call saveActor e,'data'
          end
        end

        when sAction = 'RESUMED' then do
          g.0ROWS = g.0ROWS + 1 /* row to draw arrow on */
          sParms = space(strip(strip(sParms),'LEADING','-'))
          parse var sParms sFunction sParms
          parent = peekStack(nTaskId)
          e = createElement('resumed')
          call appendChild e,parent
          call setAttributes e,,
               'seq',nSeq,,
               'row',g.0ROWS,,
               'elapsed',nElapsed,,
               'interval',getInterval(sTime),,
               'domain',sDomain,,
               'module','DFH'sModule,,
               'function',sFunction,,
               'taskid',nTaskId
          call setParmAttributes e,'exitparms',sParms
          call saveActor e,'resumed'
        end

        when sAction = 'PC' then do
          /* this trace type does not seem to add any value */
        end

        otherwise do
          parent = peekStack(nTaskId)
          call appendTextNode sEntry,parent
          say 'AUX003E Unknown trace entry <'sAction'>:' sEntry
        end
      end
    end
    sEntry = getTraceEntry()
  end
  rc = closeFile(g.0FILEIN)
  say 'AUX004I Processed' g.0K-1 'trace entries'
  say 'AUX005I Domain processing summary:'
  do i = 1 to g.0DOMAIN.0
    sDomain = g.0DOMAIN.i
    sDesc   = g.0DOMAIN.sDomain
    if bAllDomains | wordpos(sDomain,g.0DOMAIN_FILTER) > 0
    then sFilter = 'Requested'
    else sFilter = '         '
    if g.0FREQ.sDomain > 0
    then sFound  = 'Found' right(g.0FREQ.sDomain,5)
    else sFound  = '           '
    say 'AUX006I   'sFilter sFound sDomain sDesc
  end
return

saveActor: procedure expose g.
  parse arg node,sType
  sActorName = getActorName(node)
  if g.0ACTOR.sActorName = ''
  then do
    g.0ACTOR_NODES = g.0ACTOR_NODES node
    g.0ACTOR.sActorName = 1 /* we've seen this actor now */
  end
return

initStack: procedure expose g.
  parse arg task
  g.0T.task = 0         /* set top of stack index for task */
return

pushStack: procedure expose g.
  parse arg task,item
  tos = g.0T.task + 1   /* get new top of stack index for task */
  g.0E.task.tos = item  /* set new top of stack item */
  g.0T.task = tos       /* set new top of stack index */
return

popStack: procedure expose g.
  parse arg task
  tos = g.0T.task       /* get top of stack index for task */
  item = g.0E.task.tos  /* get item at top of stack */
  g.0T.task = max(tos-1,1)
return item

peekStack: procedure expose g.
  parse arg task
  tos = g.0T.task       /* get top of stack index for task */
  item = g.0E.task.tos  /* get item at top of stack */
return item

getLineContaining: procedure expose g.
  parse arg sSearchArg
  sLine = getLine(g.0FILEIN)
  do while g.0RC = 0 & pos(sSearchArg, sLine) = 0
    sLine = getLine(g.0FILEIN)
  end
return sLine

getNextLine: procedure expose g.
  sLine = getLine(g.0FILEIN)
  if g.0RC = 0
  then do
    cc = left(sLine,1)
    select
      when cc = '0' then sLine = '' /* ASA double space */
      when cc = '1' then do         /* ASA page eject */
        sLine = getLine(g.0FILEIN)  /* skip blank line after title */
        if sLine <> ''
        then say 'AUX007W Line after heading is not blank:' sLine
        sLine = getLine(g.0FILEIN)  /* read next data line */
      end
      when sLine = '<<<<  STARTING DATA FROM NEXT EXTENT  >>>>' then,
        sLine = ''
      otherwise nop
    end
  end
return sLine

getFirstTraceEntry: procedure expose g.
  sLine = getNextLine()
  parse var sLine sDomain xType sModule .
  do while g.0RC = 0 & length(sDomain) <> 2
    sLine = getNextLine()
    parse var sLine sDomain xType sModule .
  end
return getTraceEntry(sLine)

getTraceEntry: procedure expose g.
  parse arg sEntry
  /* The general format of a trace entry is something like:

Old style:
 dd tttt mmmm action ...fixed_width_stuff... parms...
                     moreparms...

               TASK-nnnnn ....timing info etc...........  =seqno=
                 1-0000  ...hex dump.... *...character dump...*
                 2-0000  ...hex dump.... *...character dump...*
                   0020  ...hex dump.... *...character dump...*
                         .
                         .
                 n-0000  ...hex dump.... *...character dump...*
                         .
                         .

New style:
 dd tttt mmmm action - parms...
                     moreparms...

               TASK-nnnnn ....timing info etc...........  =seqno=
                 1-0000  ...hex dump.... *...character dump...*
                 2-0000  ...hex dump.... *...character dump...*
                   0020  ...hex dump.... *...character dump...*
                         .
                         .
                 n-0000  ...hex dump.... *...character dump...*
                         .
                         .

  */
  sLine = getNextLine()
  do while g.0RC = 0 & left(strip(sLine),5) <> 'TASK-'
    sEntry = sEntry strip(sLine)
    sLine = getNextLine()
  end
  g.0ENTRYDATA.0 = 0
  do i = 1 while g.0RC = 0 & sLine <> ''
    g.0ENTRYDATA.i = sLine
    g.0ENTRYDATA.0 = i
    sLine = getNextLine()
  end
  g.0K = g.0K + 1
  g.0KD = g.0KD + 1
  if g.0KD >= 1000
  then do
    say 'AUX008I Processed' g.0K 'trace entries'
    g.0KD = 0
  end
return sEntry

getElapsed: procedure expose g.
  parse arg nHH':'nMM':'nSS
  nThisOffset = ((nHH*60)+nMM)*60+nSS
  if g.0FIRSTOFFSET = ''
  then g.0FIRSTOFFSET = nThisOffset
return nThisOffset - g.0FIRSTOFFSET

getInterval: procedure expose g.
  parse arg sTime
  nThisOffset = getElapsed(sTime) /* seconds from start of trace */
  if g.0PREVOFFSET = ''
  then nInterval = 0
  else nInterval = nThisOffset - g.0PREVOFFSET
  g.0PREVOFFSET = nThisOffset
return nInterval

setParmAttributes: procedure expose g.
  parse arg e,sAttrName,sParms
  /* Set parms="full list of parameters" */
  if sParms <> ''
  then call setAttribute e,sAttrName,space(sParms)
  /* Set individual name="value" attributes */
  if pos('(',sParms) > 0
  then do while sParms <> ''
    parse var sParms sName'('sValue')'sParms
    sName = getValidAttributeName(sName)
    if wordpos(sName,'FIELD-A FIELD-B') > 0
    then parse var sValue sValue .
    call setAttribute e,space(sName,0),strip(sValue)
  end
return

buildHTML: procedure expose g.
  say 'AUX009I Building HTML'

  g.0LINEDEPTH = 12

  html = getDocumentElement()
  head = createElement('head')
  call appendChild head,html
  body = createElement('body')
  call appendChild body,html

  /* Build styles */

  g.0STYLE = newElement('style','type','text/css')
  call appendChild g.0STYLE,head

  queue '.background {fill:white;}'
  queue '.top        {background-color:gray; color:white; text-align:center;}'
  queue '.sticky     {background-color:white; position:sticky; top:0;}'
  queue 'h3          {font-family:sans-serif; font-size:smaller;',
                      'margin-top:0; margin-bottom:0;}'
  queue 'p           {font-family:sans-serif; font-size:xx-small;',
                      'margin:0 0 0 0;}'
  queue '.actors     {background-color:white; padding-left:0;',
                      'text-anchor:middle;}'
  queue '.content    {background-color:white;}'
  queue '.lifeline   {stroke:lightgray; stroke-dasharray:5,2; fill:none;}'
  queue '.seq        {fill:gray;}'
  queue '.arrows     {stroke-width:2; fill:none;}'
  queue '.return     {stroke-dasharray:2,3;}'
  queue '.annotation {stroke:none; font-size:6px;}'
  queue '.ltr        {text-anchor:start;}'
  queue '.rtl        {text-anchor:end;}'
  queue '.error      {fill:red;}'
  queue 'text.dump   {font-family:monospace; font-size:10px;}'
  queue 'text        {font-family:Arial; font-size:10px; fill:black;',
                      'stroke:none;}'
  queue '.domain     {fill:whitesmoke;}'
  do queued()
    parse pull sText
    call appendTextNode sText,g.0STYLE
  end

  do i = 1 to g.0DOMAIN.0
    sDomain = g.0DOMAIN.i
    if g.0FREQ.sDomain > 0
    then do
      sColor = hsv2rgba(getHue(i),0.9,0.9,0.5)
      call appendTextNode '.domain'sDomain'   {fill:'sColor';}',g.0STYLE
    end
  end

  /* Build sticky header */

  divTop = newElement('div','class','top')
  call appendChild divTop,body

  h3 = createElement('h3')
  sAppl = getAttribute(g.0AUXTRACE,'appl')
  sDate = getAttribute(g.0AUXTRACE,'date')
  sTitle = 'CICS auxiliary trace of' sAppl 'captured on' sDate
  call appendTextNode sTitle,h3
  call appendChild h3,divTop

  p = createElement('p')
  call appendTextNode 'Created by',p
  a = newElement('a','href','https://github.com/abend0c1/aux2svg')
  call appendTextNode 'CICS Auxiliary Trace Visualizer',a
  call appendChild a,p
  call appendTextNode 'by Andrew J. Armstrong (androidarmstrong@gmail.com)',p

  call appendChild p,divTop

  divHeader = newElement('div','class','sticky')
  call appendChild divHeader,body
  svgHeader = newElement('svg','class','sticky','height',30)
  call appendChild svgHeader,divHeader

  call appendComment ' Actor headings',svgHeader
  actors = newElement('g','class','actors')
  call appendChild actors,svgHeader

  divContent = newElement('div','class','content')
  call appendChild divContent,body
  svgContent = createElement('svg')
  call appendChild svgContent,divContent

  /* Build SVG constant definitions */

  defs = createElement('defs')
  call appendChild defs,svgContent
  path = createElement('path')
  call appendChild path,defs
  call setAttributes path,,
       'id','arrow',,
       'd','M 0 0 L 10 5 L 0 10 z'

  /* Build actor headings and vertical life lines */

  call appendComment ' Life lines',svgContent
  lifelines = newElement('g','class','lifeline')
  call appendChild lifelines,svgContent

  w = 60 /* width of an actor rectangle */
  h = 22 /* height of an actor rectangle */
  x = w  /* horizontal position of actor rectangle */
  do i = 1 to words(g.0ACTOR_NODES) /* for each actor... */
    node = word(g.0ACTOR_NODES,i)
    sActorName = getActorName(node)
    sDomain = getAttribute(node,'domain')
    xMid = x + w/2
    /* Draw the life line */
    call appendComment sActorName,lifelines
    line = newElement('line','x1',xMid,'y1',h,'x2',xMid,'y2',0)
    call appendChild line,lifelines
    g.0X.sActorName = xMid /* remember where this actor is by name */
    /* Draw the rectangle to contain the actor name */
    actor = newElement('g','class','domain'sDomain)
    call appendChild actor,actors
    call addToolTip g.0DOMAIN.sDomain,actor /* Show domain desc on hover */
    rect = newElement('rect','x',x,'y',0,'width',w,'height',h,'rx',5,'ry',5)
    call appendChild rect,actor
    /* Draw the domain name and actor name within the rectangle */
    text = newElement('text','y',9)
    call appendChild text,actor
    domain = newElement('tspan','x',xMid)
    call appendChild domain,text
    tspan = newElement('tspan','x',xMid,'dy',10)
    call appendTextNode sActorName,tspan
    call appendChild tspan,text
    select
      when isProgram(node) then call appendTextNode 'program',domain
      when isSocket(node)  then call appendTextNode 'socket',domain
      otherwise call appendTextNode sDomain,domain
    end
    x = x + w + 5
  end

  nImageWidth = x + w /* room on the right for a longish message */

  /* Build arrows between actors */

  call appendComment ' Actor relationships',svgContent
  arrows = newElement('g','class','arrows')
  call appendChild arrows,svgContent

  g.0FIRSTARROW = 2 * g.0LINEDEPTH /* vertical offset of first arrow */
  tasks = getChildren(g.0AUXTRACE)
  do i = 1 to words(tasks)
    task = word(tasks,i)
    nTaskId = getAttribute(task,'taskid')
    h = getHue(i)
    s = getSaturation(i)
    v = getValue(i)
    sColor = hsv2rgba(h,s,v)
    call appendTextNode '.task'nTaskId ' {stroke:'sColor';}',g.0STYLE
    call appendTextNode '.fill'nTaskId ' {fill:'sColor';}',g.0STYLE
    call createMarkers defs,nTaskId /* Create colored arrowhead for this task */
    call drawArrowsForTask arrows,task
  end

  /* Now we know the image height we can set the viewbox */

  nImageHeight = (2 + g.0ROWS + 1 ) * g.0LINEDEPTH
  call setAttributes svgContent,,
       'height',nImageHeight,,
       'width',nImageWidth,,
       'viewBox','0 22' nImageWidth nImageHeight
  g.0WIDTH = nImageWidth
  g.0HEIGHT = nImageHeight

  call setAttributes svgHeader,,
       'width',nImageWidth,,
       'viewbox','0 0' nImageWidth '22'

  /* Update the lifeline depth */

  nodes = getElementsByTagName(lifelines,'line')
  do i = 1 to words(nodes)
    node = word(nodes,i)
    call setAttribute node,'y2',nImageHeight
  end

return

drawArrowsForTask: procedure expose g.
  parse arg arrows,task
  sClass = 'task'getAttribute(task,'taskid')
  g = newElement('g','class',sClass)
  call appendChild g,arrows
  call drawArrows g,task
return

drawArrows: procedure expose g.
  parse arg g,source
  if isActor(source)
  then do
    children = getChildren(source)
    do i = 1 to words(children)
      target = word(children,i)
      if isActor(target)
      then do /* we can draw an arrow between source and target actors */
        group = newElement('g')
        call appendChild group,g
        call drawArrow group,source,target,'call'
        call drawArrows group,target
        call drawArrow group,target,source,'return'
      end
      else do
        call drawArrows g,target
      end
    end
  end
/* TODO: is this really necessary?
  else do
    children = getChildren(source)
    do i = 1 to words(children)
      child = word(children,i)
      call drawArrows g,child
    end
  end
*/
return

isActor: procedure expose g.
  parse arg node
  bIsActor = getActorName(node) <> '' | getNodeName(node) = 'task'
return bIsActor

drawArrow: procedure expose g.
  parse arg g,source,target,sClass
  /* the source actor invokes a function on the target actor */
  bIsCall = sClass = 'call' /* ...else it is a return arrow */
  if bIsCall
  then nRow = getAttribute(target,'row')
  else nRow = getAttribute(source,'exitrow')
  if nRow = '' then return /* <event> has no 'return' arrow */
  y = g.0FIRSTARROW + g.0LINEDEPTH * nRow
  sSourceActor = getActorName(source)
  sTargetActor = getActorName(target)
  sFunction = getAttribute(target,'function')

  /* Group the arrow, text and optional tooltip together */
  if sSourceActor = sTargetActor
  then sClasses = sSourceActor
  else sClasses = sSourceActor sTargetActor
  arrow = newElement('g','class',sClasses)
  call appendChild arrow,g

  /* Draw the elapsed time and task id of this <trace> entry */
  sTaskId = getAttribute(target,'taskid')
  if bIsCall
  then do
    call appendComment ' 'sTargetActor,arrow
    elapsed = newElement('text','x',0,'y',y)
    call appendChild elapsed,arrow
    nElapsed = getAttribute(target,'elapsed')
    sElapsed = '+'left(format(nElapsed,,6),8,'0')' 'sTaskId
    call appendTextNode sElapsed,elapsed
  end

  /* Compute the start and end positions of this arrow */
  x1 = g.0X.sSourceActor
  x2 = g.0X.sTargetActor
  if x1 < x2 /* if left-to-right arrow */
  then do
    x1b = x1 + 2
    x2 = x2 - 2
    sDirection = 'ltr' /* Direction of arrow is left-to-right */
  end
  else do
    x1b = x1 - 2
    x2 = x2 + 2
    sDirection = 'rtl' /* Direction of arrow is right-to-left */
  end

  /* Draw either an arrow or a circle */
  if sSourceActor = sTargetActor
  then do /* Draw a circle on the target actor lifeline */
    x = g.0X.sTargetActor
    circle = newElement('circle','stroke-width','4','r',1,'cx',x,'cy',y)
    call appendChild circle,arrow
  end
  else do /* Draw a line from the source actor to the target actor */
    line = createElement('line')
    call appendChild line,arrow
    if \bIsCall /* class="return" causes the line to be dotted */
    then call setAttribute line,'class',sClass
    sId = 'Arrow'sTaskId
    call setAttributes line,,
         'x1',x1,,
         'y1',y,,
         'x2',x2,,
         'y2',y,,
         'marker-end','url(#'sId')'
  end

  /* Annotate the arrow (or circle) */
  annotation = newElement('text',,
                         'class','annotation' sDirection,,
                         'x',x1b,,
                         'y',y-2)
  call appendChild annotation,arrow
  if bIsCall
  then do /* annotate the invoking arrow (solid line) */
    sExtra = getDescriptionOfCall(target)
    sModule = getAttribute(target,'module')
    if getNodeName(target) = 'exception'
    then call setAttribute annotation,'class','annotation error' sDirection
  end
  else do /* annotate the returning arrow (dotted line) */
    sExtra = ''
    sModule = getAttribute(source,'module')
    sFunction = getAttribute(source,'function')
    sResponse = getAttribute(source,'response')
    if sResponse = '' |,
       sResponse = 'NORMAL' |,
       sResponse = 'RESPONSE(OK)'
    then sResponse = 'OK' /* normalise a good response to just 'OK' */
    select
      when sSourceActor = sTargetActor then,
        sExtra = sFunction sResponse
      when sResponse = 'OK' then,
        sExtra = sResponse
      otherwise,
        sExtra = sResponse getAttribute(source,'reason')
    end
    if sResponse <> 'OK' /* Highlight the abnormal response */
    then call setAttribute annotation,'class','annotation error' sDirection
  end

  /* Every arrow is annotated with at least the trace sequence number */
  tspanSeq = createElement('tspan')
  call setAttribute tspanSeq,'class','seq'
  if bIsCall
  then nSeq = getAttribute(target,'seq')
  else nSeq = getAttribute(source,'exitseq')
  call appendTextNode nSeq,tspanSeq

  /* Some arrows have extra info near the sequence number */
  if sDirection = 'ltr' /* if left-to-right arrow */
  then do /* e.g. 001234 LOAD_EXEC ------------------>  */
    call appendChild tspanSeq,annotation
    if sExtra <> ''
    then do
      tspanExtra = createElement('tspan')
      call appendTextNode sExtra,tspanExtra
      call appendChild tspanExtra,annotation
    end
  end
  else do /* e.g. <----------- PROGRAM_NOT_FOUND 001235 */
    if sExtra <> ''
    then do
      tspanExtra = createElement('tspan')
      call appendTextNode sExtra,tspanExtra
      call appendChild tspanExtra,annotation
    end
    call appendChild tspanSeq,annotation
  end

  /* Now create an appropriate tool tip for this line */
  sTip = nSeq sExtra
  sTargetNodeName = getNodeName(target)
  select
    when sModule = 'DFHSOCK' then do
      if sFunction = 'SEND'
      then sTip = sTip getSocketDetail(target,'on-entry')
      if sFunction = 'RECEIVE'
      then sTip = sTip getSocketDetail(source,'on-exit')
    end
    when sTargetNodeName = 'data' then do
      sTip = sTip getDataDetail(target)
    end
    when sTargetNodeName = 'trace' | sTargetNodeName = 'task' then do
      if bIsCall
      then sTip = sTip getAttribute(target,'entryparms')
      else sTip = sTip getAttribute(source,'exitparms')
    end
    when sTargetNodeName = 'exception' then do
      sTip = sTip getAttribute(target,'parms')
    end
    when sTargetNodeName = 'event' then do
      sTip = sTip getAttribute(target,'parms')
    end
    otherwise nop
  end
  call addTooltip sTip,arrow /* tool tip for this arrow */
return

/*
  This is a helper routine that creates a named element and
  optionally sets one or more attributes on it. Note Rexx only allows
  up to 20 arguments to be passed.
*/
newElement: procedure expose g.
  parse arg sName /* attrname,attrvalue,attrname,attrvalue,... */
  id = createElement(sName)
  do i = 2 to arg() by 2
    call setAttribute id,arg(i),arg(i+1)
  end
return id

/*
  This is a helper routine that appends text to the body of
  an element.
*/
appendTextNode: procedure expose g.
  parse arg sText,parent
  call appendChild createTextNode(sText),parent
return

/*
  This is a helper routine that appends a comment to an element
*/
appendComment: procedure expose g.
  parse arg sText,parent
  call appendChild createComment(sText),parent
return

createMarkers: procedure expose g.
  parse arg defs,nTaskId
/*
    <marker id="ArrowXXXXX" viewBox="0 0 10 10" refX="7" refY="5"
            orient="auto">
      <use href="#arrow"/>
    </marker>
*/
  marker = newElement('marker',,
                      'id','Arrow'nTaskId,,
                      'class','fill'nTaskId,,
                      'viewBox','0 0 10 10',,
                      'refX',7,,
                      'refY',5,,
                      'orient','auto')
  call appendChild marker,defs
  use = newElement('use','href','#arrow')
  call appendChild use,marker
return

addTooltip: procedure expose g.
  parse arg sTip,node
  tooltip = createElement('title')
  call appendChild tooltip,node
  call appendTextNode sTip,tooltip
return

getHue: procedure expose g.
  arg n
return (g.0HUE_INIT + (n-1) * g.0HUE_STEP) // 360

getSaturation: procedure expose g.
  arg n
  n = g.0SAT_LEVELS - 1 - (n-1) // g.0SAT_LEVELS
return g.0SAT_MIN + n * g.0SAT_STEP

getValue: procedure expose g.
  arg n
  n = g.0VAL_LEVELS - 1 - (n-1) // g.0VAL_LEVELS
return g.0VAL_MIN + n * g.0VAL_STEP

hsv2rgba: procedure
  parse arg h,s,v,a
  /*
  Hue (h) is from 0 to 360, where 0 = red and 360 also = red
  Saturation (s) is from 0.0 to 1.0 (0 = least color, 1 = most color)
  Value (v) is from 0.0 to 1.0 (0 = darkest, 1 = brightest)
  Alpha (a) is from 0.0 to 1.0 (0 = transparent, 1 = opaque)
  */
  if \datatype(a,'NUMBER') then a = 1.0
  v = 100 * v /* convert to a percentage */
  if s = 0 /* if grayscale */
  then do
    v = format(v,,2)'%'
    rgb = 'rgba('v','v','v','a')'
  end
  else do
    sextant = trunc(h/60) /* 0 to 5 */
    fraction = h/60 - sextant
    p = v * (1 - s)
    q = v * (1 - s * fraction)
    r = v * (1 - s * (1 - fraction))
    v = format(v,,2)'%'
    p = format(p,,2)'%'
    q = format(q,,2)'%'
    r = format(r,,2)'%'
    select
      when sextant = 0 then rgb = 'rgba('v','r','p','a')'
      when sextant = 1 then rgb = 'rgba('q','v','p','a')'
      when sextant = 2 then rgb = 'rgba('p','v','r','a')'
      when sextant = 3 then rgb = 'rgba('p','q','v','a')'
      when sextant = 4 then rgb = 'rgba('r','q','v','a')'
      when sextant = 5 then rgb = 'rgba('v','p','q','a')'
      otherwise rgb = 'rgb(0,0,0)' /* should not happen :) */
    end
  end
return rgb

getActorName: procedure expose g.
  parse arg node
  select
    when node = g.0AUXTRACE then do
      sActorName = 'CICS'
    end
    when getNodeName(node) = 'task' then do
      sActorName = 'CICS'
    end
    when isProgram(node) then do
      sActorName = getAttribute(node,'PROGRAM_NAME')
      if sActorName = '' then sActorName = getAttribute(node,'PROGRAM')
      if sActorName = '' then sActorName = 'program'
    end
    when isSocket(node) then do
      sActorName = getAttribute(node,'SOCKET_TOKEN')
      if sActorName = '' then sActorName = 'socket'
    end
    otherwise sActorName = getAttribute(node,'module')
  end
return sActorName

isProgram: procedure expose g.
  parse arg node
  sDomain = getAttribute(node,'domain')
  sFunction = getAttribute(node,'function')
  select
    when sDomain = 'PG',
       & wordpos(sFunction,'LINK LINK_EXEC INITIAL_LINK',
                           'LOAD LOAD_EXEC LINK_URM') > 0,
         then bIsProgram = 1
    when sDomain = 'AP' & sFunction = 'START_PROGRAM',
         then bIsProgram = 1
    otherwise bIsProgram = 0
  end
return bIsProgram

isSocket: procedure expose g.
  parse arg node
  sModule = getAttribute(node,'module')
  sFunction = getAttribute(node,'function')
  bIsSocket = sModule = 'DFHSOCK' &,
     wordpos(sFunction,'SEND RECEIVE CONNECT CLOSE') > 0
return bIsSocket

getSocketDetail: procedure expose g.
  parse arg node,sContainer
  detail = getChildrenByName(node,sContainer)
  args = getChildrenByName(detail,'arg')
  if words(args) < 2 then return ''
  data = word(args,2) /* arg2 contains the packet payload */
  sData = getText(getFirstChild(data)) /* ...a CDATA node */
return sData

getDataDetail: procedure expose g.
  parse arg node
  sData = ''
  detail = getChildrenByName(node,'detail')
  if detail <> ''
  then do
    args = getChildrenByName(detail,'arg')
    do i = 1 to words(args)
      data = word(args,i)
      sData = sData getText(getFirstChild(data))
    end
  end
return sData

getDescriptionOfCall: procedure expose g.
  parse arg node
  sDesc = ''
  sDomain = getAttribute(node,'domain')
  sFunction = getAttribute(node,'function')
  select
    when sDomain = 'PG' then do
      sProgram = getAttribute(node,'PROGRAM_NAME')
      select
        when sProgram <> '' then,
          sDesc = '('sProgram')'
        otherwise nop
      end
    end
    when sDomain = 'AP' then do
      select
        when sFunction = 'START_PROGRAM' then,
          sDesc = '('getAttribute(node,'PROGRAM')')'
        when sFunction = 'WRITE_TRANSIENT_DATA' then,
          sDesc = '('getAttribute(node,'QUEUE')')'
        when sFunction = 'READ_UPDATE_INTO' then,
          sDesc = '('getAttribute(node,'FILE_NAME')')'
        when sFunction = 'LOCATE' then,
          sDesc = getAttribute(node,'TABLE')'(' ||,
                  getAttribute(node,'KEY')')'
        when wordpos(sFunction,'GET_QUEUE',
                               'PUT_QUEUE',
                               'DELETE_QUEUE') > 0 then,
          sDesc = '('getAttribute(node,'RECORD_TYPE')')'
        otherwise nop
      end
    end
    when sDomain = 'BA' then do
      select
        when wordpos(sFunction,'PUT_CONTAINER',
                               'GET_CONTAINER_SET',
                               'GET_CONTAINER_INTO',
                               'DELETE_CONTAINER') > 0 then,
          sDesc = '('getAttribute(node,'CONTAINER_NAME')')'
        when wordpos(sFunction,'ADD_ACTIVITY',
                               'LINK_ACTIVITY',
                               'CHECK_ACTIVITY') > 0 then,
          sDesc = '('getAttribute(node,'ACTIVITY_NAME')')'
        otherwise nop
      end
    end
    when sDomain = 'WB' then do
      select
        when wordpos(sFunction,'PUT_QUEUE',
                               'DELETE_QUEUE',
                               'GET_QUEUE') > 0 then,
          sDesc = '('getAttribute(node,'RECORD_TYPE')')'
        when wordpos(sFunction,'START_BROWSE',
                               'READ_NEXT',
                               'END_BROWSE') > 0 then,
          sDesc = '('getAttribute(node,'DATA_TYPE')')'
        otherwise nop
      end
    end
    when sDomain = 'SM' then do
      select
        when sFunction = 'GETMAIN' then do
            if hasAttribute(node,'STORAGE_CLASS')
            then do
              xLen = getAttribute(node,'GET_LENGTH')
              sDesc = getAttribute(node,'ADDRESS'),
                      getAttribute(node,'STORAGE_CLASS'),
                      "LENGTH=X'"xLen"' ("x2d(xLen)')',
                      getAttribute(node,'REMARK')
            end
            else,
              sDesc = getAttribute(node,'ADDRESS'),
                      'SUBPOOL',
                      getAttribute(node,'REMARK')
        end
        when sFunction = 'FREEMAIN' then do
          select
            when hasAttribute(node,'STORAGE_CLASS') then,
              sDesc = getAttribute(node,'ADDRESS'),
                      getAttribute(node,'STORAGE_CLASS'),
                      getAttribute(node,'REMARK')
            when hasAttribute(node,'SUBPOOL_TOKEN') then,
              sDesc = getAttribute(node,'ADDRESS'),
                      'SUBPOOL',
                      getAttribute(node,'REMARK')
            otherwise,
              sDesc = getAttribute(node,'ADDRESS'),
                      getAttribute(node,'REMARK')
          end
        end
        otherwise nop
      end
    end
    when sDomain = 'DD' then do
      select
        when sFunction = 'LOCATE' then,
          sDesc = getAttribute(node,'DIRECTORY_NAME')'(' ||,
                  getAttribute(node,'NAME')')'
        otherwise nop
      end
    end
    when sDomain = 'TS' then do
      select
        when wordpos(sFunction,'MATCH',
                               'DELETE',
                               'READ_INTO',
                               'READ_SET',
                               'READ_AUX_DATA',
                               'WRITE') > 0 then,
          sDesc = 'QUEUE('getAttribute(node,'QUEUE_NAME')')'
        otherwise nop
      end
    end
    when sDomain = 'XS' then do
      select
        when sFunction = 'CHECK_CICS_RESOURCE' then,
          sDesc = getAttribute(node,'RESOURCE_TYPE')'(' ||,
                  getAttribute(node,'RESOURCE')') ACCESS(' ||,
                  getAttribute(node,'ACCESS')')'
        otherwise nop
      end
    end
    when sDomain = 'XM' then do
      select
        when sFunction = 'ATTACH' then,
          sDesc = 'TRANS('getAttribute(node,'TRANSACTION_ID')')'
        when sFunction = 'INQUIRE_MXT' then,
          sDesc = 'LIMIT('getAttribute(node,'MXT_LIMIT')')',
                  'ACTIVE('getAttribute(node,'CURRENT_ACTIVE')')'
        otherwise nop
      end
    end
    when sDomain = 'EM' then do
      select
        when wordpos(sFunction,'FIRE_EVENT',
                               'DEFINE_ATOMIC_EVENT',
                               'DELETE_EVENT',
                               'RETRIEVE_REATTACH_EVENT') > 0 then,
          sDesc = '('getAttribute(node,'EVENT')')'
        otherwise nop
      end
    end
    when sDomain = 'DU' then do
      select
        when wordpos(sFunction,'TRANSACTION_DUMP',
                               'COMMIT_TRAN_DUMPCODE',
                               'LOCATE_TRAN_DUMPCODE') > 0 then,
          sDesc = '('getAttribute(node,'TRANSACTION_DUMPCODE')')',
                     getAttribute(node,'DUMPID')
        when wordpos(sFunction,'INQUIRE_SYSTEM_DUMPCODE') > 0 then,
          sDesc = '('getAttribute(node,'SYSTEM_DUMPCODE')')'
        otherwise nop
      end
    end
    when sDomain = 'CC' then do
      select
        when wordpos(sFunction,'GET') > 0 then,
          sDesc = getAttribute(node,'TYPE')'(' ||,
                  getAttribute(node,'NAME')')'
        otherwise nop
      end
    end
    when sDomain = 'GC' then do
      select
        when wordpos(sFunction,'WRITE') > 0 then,
          sDesc = getAttribute(node,'TYPE')'(' ||,
                  getAttribute(node,'NAME')')'
        otherwise nop
      end
    end
    when sDomain = 'DS' then do
      select
        when wordpos(sFunction,'SUSPEND',
                               'WAIT_MVS',
                               'WAIT_OLDW') > 0 then,
          sDesc = getAttribute(node,'RESOURCE_TYPE')'(' ||,
                  getAttribute(node,'RESOURCE_NAME')')'
        otherwise nop
      end
    end
    otherwise nop
  end
  if getNodeName(node) = 'trace'
  then sPrefix = sFunction
  else sPrefix = getNodeName(node)':' sFunction
return strip(sPrefix sDesc)

setOptions: procedure expose g.
  parse arg sOptions
  /* Set default options  */
  g.0OPTION.EVENT   = 1 /* Process input EVENT trace records? */
  g.0OPTION.DATA    = 1 /* Process input DATA trace records? */
  g.0OPTION.DETAIL  = 0 /* Output trace detail? */
  g.0OPTION.XML     = 0 /* Output XML file? */
  g.0OPTION.HTML    = 1 /* Output HTML file? */
  g.0DOMAIN_FILTER = ''
  do i = 1 to words(sOptions)
    sOption = word(sOptions,i)
      if length(sOption) = 2 then,
        g.0DOMAIN_FILTER = g.0DOMAIN_FILTER sOption
      else do
        if left(sOption,2) = 'NO'
        then do
          sOption = substr(sOption,3)
          g.0OPTION.sOption = 0
        end
        else g.0OPTION.sOption = 1
      end
  end
return

Prolog:
  if g.0ENV = 'TSO'
  then g.0LF = '15'x
  else g.0LF = '0A'x

  /* Constants for generating line colors */
  g.0HUE_INIT   = 151 /* random(0,360) */
  g.0HUE_STEP   = 43  /* random(0,360) */
  g.0SAT_MIN    = 1.0
  g.0SAT_MAX    = 1.0
  g.0SAT_LEVELS = 2
  g.0SAT_STEP   = (g.0SAT_MAX - g.0SAT_MIN) / (g.0SAT_LEVELS - 1)
  g.0VAL_MIN    = 0.5
  g.0VAL_MAX    = 0.8
  g.0VAL_LEVELS = 2
  g.0VAL_STEP   = (g.0VAL_MAX - g.0VAL_MIN) / (g.0VAL_LEVELS - 1)

  g.0DOMAIN.0 = 0 /* Number of domains */
  call addDomain 'AP','Application Domain'
  call addDomain 'BA','Business Application Manager Domain'
  call addDomain 'CC','CICS Catalog Domain'
  call addDomain 'DD','Directory Domain'
  call addDomain 'DH','Document Handler Domain'
  call addDomain 'DM','Domain Manager Domain'
  call addDomain 'DP','Debugging Profiles Domain'
  call addDomain 'DS','Dispatcher Domain'
  call addDomain 'DU','Dump Domain'
  call addDomain 'EI','External CICS Interface over TCP/IP Domain'
  call addDomain 'EJ','Enterprise Java Domain'
  call addDomain 'EM','Event Manager Domain'
  call addDomain 'EP','Event Processing Domain'
  call addDomain 'EX','External CICS Interface Domain'
  call addDomain 'FT','Feature Domain'
  call addDomain 'GC','Global Catalog Domain'
  call addDomain 'IE','IP ECI Domain'
  call addDomain 'II','IIOP Domain'
  call addDomain 'IS','Inter-System Domain'
  call addDomain 'KE','Kernel Domain'
  call addDomain 'LC','Local Catalog Domain'
  call addDomain 'LD','Loader Domain'
  call addDomain 'LG','Log Manager Domain'
  call addDomain 'LM','Lock Manager Domain'
  call addDomain 'ME','Message Domain'
  call addDomain 'ML','Markup Language Domain'
  call addDomain 'MN','Monitoring Domain'
  call addDomain 'MP','Managed Platform Domain'
  call addDomain 'NQ','Enqueue Domain'
  call addDomain 'OT','Object Transaction Domain'
  call addDomain 'PA','Parameter Manager Domain'
  call addDomain 'PG','Program Manager Domain'
  call addDomain 'PI','Pipeline Manager Domain'
  call addDomain 'PT','Partner Domain'
  call addDomain 'RL','Resource Life-cycle Domain'
  call addDomain 'RM','Recovery Manager Domain'
  call addDomain 'RS','Region Status Domain'
  call addDomain 'RX','RRMS Domain'
  call addDomain 'RZ','Request Streams Domain'
  call addDomain 'SH','Scheduler Domain'
  call addDomain 'SJ','Java Virtual Machine Domain'
  call addDomain 'SM','Storage Manager Domain'
  call addDomain 'SO','Socket Domain'
  call addDomain 'ST','Statistics Domain'
  call addDomain 'TI','Timer Domain'
  call addDomain 'TR','Trace Domain'
  call addDomain 'TS','Temporary Storage Domain'
  call addDomain 'US','User Domain'
  call addDomain 'WB','Web Domain'
  call addDomain 'W2','Web 2.0 Domain'
  call addDomain 'XM','Transaction Manager Domain'
  call addDomain 'XS','Security Manager Domain'
return

addDomain: procedure expose g.
  parse arg sDomain,sDesc
  if g.0DOMAIN.sDomain = ''
  then do
    nDomain = g.0DOMAIN.0       /* Number of domains */
    nDomain = nDomain + 1
    g.0DOMAIN.sDomain = sDesc   /* e.g. g.0DOMAIN.AP = 'App Domain'  */
    g.0DOMAIN.nDomain = sDomain /* e.g. g.0DOMAIN.1 = 'AP'           */
    g.0DOMAIN.0 = nDomain
  end
return

Epilog: procedure expose g.
return


getValidAttributeName: procedure expose g.
  parse arg sName
  sName = space(sName,0)
  sName = strip(sName,'LEADING','-')
  if datatype(left(sName,1),'WHOLE')
  then sName = 'X'sName /* must start with an alphabetic */
return sName


appendDetail: procedure expose g.
  parse arg e,sName
  x = createElement(sName)
  call appendChild x,e
  sData = ''
  do i = 2 to g.0ENTRYDATA.0
    sLine = strip(g.0ENTRYDATA.i,'LEADING')
    parse var sLine nArg'-0000 '
    if datatype(nArg,'WHOLE')
    then do
      if sData <> ''
      then call appendDetailArg x,sData
      parse var sLine nArg'-'sData
      sData = sData || g.0LF
    end
    else do
      sData = sData || sLine || g.0LF
    end
  end
  if sData <> ''
  then call appendDetailArg x,sData
return

appendDetailArg: procedure expose g.
  parse arg parent,sData
  a = createElement('arg')
  call appendChild a,parent
  call appendChild createCDATASection(g.0LF || sData),a
return

/*REXX 2.0.0
Copyright (C) 2003-2020 Andrew J. Armstrong
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

/*REXX*****************************************************************
**                                                                   **
** NAME     - PRETTY                                                 **
**                                                                   **
** FUNCTION - Pretty printer. This demonstrates the XML parser by    **
**            reformatting an xml input file.                        **
**                                                                   **
**                                                                   **
** SYNTAX   - pretty infile [outfile] (options...)                   **
**                                                                   **
**            Where,                                                 **
**            infile   = Name of file to be parsed                   **
**            outfile  = Name of file to store the pretty output in. **
**                       The default is the console.                 **
**            options  = NOBLANKS - Suppress whitespace-only nodes   **
**                       DEBUG    - Display some debugging info      **
**                       DUMP     - Display the parse tree           **
**                                                                   **
**                                                                   **
** NOTES    - 1. You will have to either append the PARSEXML source  **
**               manually to this demo source, or run this demo      **
**               source through the REXXPP rexx pre-processor.       **
**                                                                   **
**               To use the pre-processor, run:                      **
**                                                                   **
**               rexxpp pretty prettypp                              **
**                                                                   **
**               ...and then run the resulting rexx procedure over   **
**               an XML file of your choice:                         **
**                                                                   **
**               prettypp testxml [outxml]                           **
**                ...or...                                           **
**               prettypp testxml [outxml] (noblanks                 **
**                ...or...                                           **
**               prettypp testxml [outxml] (noblanks dump            **
**                                                                   **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong@gmail.com>       **
**                                                                   **
** HISTORY  - Date     By       Reason (most recent at the top pls)  **
**            -------- -------- ------------------------------------ **
**            20200628 AJA Added showNodeNonRecursive function.      **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20050920 AJA      Allow root node to be specified.     **
**            20050907 AJA      Escape text of attribute values.     **
**            20040706 AJA      Assume default indentation amount.   **
**                              Allow output to a file.              **
**            20031031 AJA      Fix escaping text.                   **
**            20030911 AJA      Removed default filename value. You  **
**                              must specify your own filename.      **
**            20030905 AJA      Intial version.                      **
**                                                                   **
**********************************************************************/

  parse arg sFileIn sFileOut' ('sOptions')'

  /* Initialise the parser */
  call initParser sOptions /* <-- This is in PARSEXML rexx */

  /* Open the specified file and parse it */
  nParseRC = parseFile(sFileIn)

  parse source g.0ENV .
  if g.0ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.0LINES = 0
    g.0NONRECURSIVE = 1
  end

  call prettyPrinter sFileOut,2 /* 2 is the indentation amount */

exit nParseRC

/*-------------------------------------------------------------------*
 * An example of how to navigate the tree
 *-------------------------------------------------------------------*/

prettyPrinter: procedure expose g.
  parse arg sFileOut,g.0TAB,nRoot
  if g.0TAB = '' then g.0TAB = 2 /* indentation amount */
  if nRoot = '' then nRoot = getRoot()
  g.0INDENT = 0
  g.0FILEOUT = ''
  if sFileOut <> ''
  then do
    g.0FILEOUT = openFile(sFileOut,'OUTPUT')
    if g.0rc = 0
    then say 'PRP001I Creating' sFileOut
    else do
      say 'PRP002E Could not create' sFileOut'. Writing to console...'
      g.0FILEOUT = '' /* null handle means write to console */
    end
  end

  call _setDefaultEntities

  if g.0NONRECURSIVE = 1
  then do
    call showNodeNonRecursive nRoot
   end
  else do
    g.0INDENT = -g.0TAB
    call showNode nRoot
  end

  if g.0FILEOUT <> ''
  then do
    say 'PRP002I Created' sFileOut
    rc = closeFile(g.0FILEOUT)
  end
return

showNodeNonRecursive: procedure expose g.
  parse arg topNodeAgain
  g.0INDENT = 0
  node = topNodeAgain
  do until node = topNodeAgain | node = 0
    if g.0SEEN.node = ''
    then call emitBegin node
    else call emitEnd node
    g.0SEEN.node = 1
    if g.0SOUTH.node = '' then do
      g.0SOUTH.node = 1
      if hasChildren(node)
      then do
        node = getFirstChild(node)
      end
      else do
        call emitEnd node
        nextSibling = getNextSibling(node)
        if nextSibling = ''
        then node = getParent(node)
        else node = nextSibling
      end
    end
    else do
      nextSibling = getNextSibling(node)
      if nextSibling = ''
      then node = getParent(node)
      else node = nextSibling
    end
  end
  call emitEnd node
return

emitBegin: procedure expose g.
  parse arg node
  select
    when _canHaveChildren(node) then call emitElementNodeNonRecursive(node)
    when isTextNode(node)    then call emitTextNode(node)
    when isCommentNode(node) then call emitCommentNode(node)
    when isCDATA(node)       then call emitCDATA(node)
    otherwise nop
  end
  g.0INDENT = g.0INDENT + 2
return

emitEnd: procedure expose g.
  parse arg node
  g.0INDENT = g.0INDENT - 2
  if hasChildren(node)
  then call Say '</'getName(node)'>'
return

emitElementNodeNonRecursive: procedure expose g.
  parse arg node
  if hasChildren(node)
  then call Say '<'getName(node)getAttrs(node)'>'
  else call Say '<'getName(node)getAttrs(node)'/>'
return

getAttrs: procedure expose g.
  parse arg node
  sAttrs = ''
  do i = 1 to getAttributeCount(node)
    sAttrs = sAttrs getAttributeName(node,i)'="' ||,
                    escapeText(getAttribute(node,i))'"'
  end
return sAttrs

showNode: procedure expose g.
  parse arg node
  g.0INDENT = g.0INDENT + g.0TAB
  select
    when isTextNode(node)    then call emitTextNode    node
    when isCommentNode(node) then call emitCommentNode node
    when isCDATA(node)       then call emitCDATA       node
    otherwise                     call emitElementNode node
  end
  g.0INDENT = g.0INDENT - g.0TAB
return

setPreserveWhitespace: procedure expose g.
  parse arg bPreserve
  g.0PRESERVEWS = bPreserve = 1
return

emitTextNode: procedure expose g.
  parse arg node
  if g.0ESCAPETEXT = 0
  then call Say getText(node)
  else do
    if g.0PRESERVEWS = 1
    then call Say escapeText(getText(node))
    else call Say escapeText(removeWhitespace(getText(node)))
  end
return

emitCommentNode: procedure expose g.
  parse arg node
  call Say '<!--'getText(node)' -->'
return

emitCDATA: procedure expose g.
  parse arg node
  call Say '<![CDATA['getText(node)']]>'
return

emitElementNode: procedure expose g.
  parse arg node
  sName = getName(node)
  sAttrs = ''
  do i = 1 to getAttributeCount(node)
    sAttrs = sAttrs getAttributeName(node,i)'="' ||,
                    escapeText(getAttribute(node,i))'"'
  end
  sChildren = getChildren(node)
  if sChildren = ''
  then do
    if sAttrs = ''
    then call Say '<'sName'/>'
    else call Say '<'sName strip(sAttrs)'/>'
  end
  else do
    if sAttrs = ''
    then call Say '<'sName'>'
    else call Say '<'sName strip(sAttrs)'>'
    child = getFirstChild(node)
    do while child <> ''
      call showNode child
      child = getNextSibling(child)
    end
    call Say '</'sName'>'
  end
return

Say: procedure expose g.
  parse arg sMessage
  sLine = copies(' ',g.0INDENT)sMessage
  if g.0FILEOUT = ''
  then say sLine
  else call putLine g.0FILEOUT,sLine
return

/*REXX 2.0.0
Copyright (c) 2009-2020, Andrew J. Armstrong
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

/*REXX*****************************************************************
**                                                                   **
** NAME     - IO                                                     **
**                                                                   **
** FUNCTION - Simple I/O routines.                                   **
**                                                                   **
** API      - The routines in this module are:                       **
**                                                                   **
**            openFile(filename,options,attrs)                       **
**                Opens the specified file with the specified options**
**                and returns a file handle to be used in other I/O  **
**                operations. By default the file will be opened for **
**                input. Specify 'OUTPUT' to open it for output.     **
**                For TSO, you can specify any operand of the TSO    **
**                ALLOCATE command in the third operand. For example:**
**                rc = openFile('MY.FILE','OUTPUT','RECFM(F,B)'      **
**                              'LRECL(80) BLKSIZE(27920)')          **
**                                                                   **
**            closeFile(handle)                                      **
**                Closes the file specified by 'handle' (which was   **
**                returned by the openFile() routine.                **
**                                                                   **
**            getLine(handle)                                        **
**                Reads the next line from the file specified by     **
**                'handle'.                                          **
**                                                                   **
**            putLine(handle,data)                                   **
**                Appends the specified data to the file specified   **
**                by 'handle'.                                       **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --------------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20061017 AJA Added support for UNIX environment.       **
**                         Tested on Ubuntu Linux 6.06 LTS.          **
**            20050930 AJA Initial version.                          **
**                                                                   **
**********************************************************************/

  parse source . . sSourceFile .
  parse value sourceline(1) with . sVersion
  say 'Simple Rexx I/O routines' sVersion
  say 'You cannot invoke this rexx by itself!'
  say
  say 'This rexx is a collection of subroutines to be called'
  say 'from your own rexx procedures. You should either:'
  say '  - Append this procedure to your own rexx procedure,'
  say '    or,'
  say '  - Append the following line to your rexx:'
  say '    /* INCLUDE' sSourceFile '*/'
  say '    ...and run the rexx preprocessor:'
  say '    rexxpp myrexx myrexxpp'
  say '    This will create myrexxpp by appending this file to myrexx'
exit

/*-------------------------------------------------------------------*
 * Open a file
 *-------------------------------------------------------------------*/

openFile: procedure expose g.
  parse arg sFile,sOptions,sAttrs
  hFile = ''
  select
    when g.0ENV = 'TSO' then do
      bOutput = wordpos('OUTPUT',sOptions) > 0
      bQuoted = left(sFile,1) = "'"
      if bQuoted then sFile = strip(sFile,,"'")
      parse var sFile sDataset'('sMember')'
      if sMember <> '' then sFile = sDataset
      if bQuoted then sFile = "'"sFile"'"
      if bOutput
      then 'LMINIT  DATAID(hFile) DATASET(&sFile) ENQ(EXCLU)'
      else 'LMINIT  DATAID(hFile) DATASET(&sFile)'
      if sMember <> ''
      then do /* Open a member of a PDS */
        'LMOPEN  DATAID(&hFile) OPTION(INPUT)' /* Input initially */
        /* ... can't update ISPF stats when opened for output */
        g.0MEMBER.hFile = sMember
        'LMMFIND DATAID(&hFile) MEMBER('sMember') STATS(YES)'
        if bOutput
        then do
          if rc = 0
          then g.0STATS.hFile = zlvers','zlmod','zlc4date
          else g.0STATS.hFile = '1,0,0000/00/00'
          'LMCLOSE DATAID(&hFile)'
          'LMOPEN  DATAID(&hFile) OPTION(&sOptions)'
        end
      end
      else do /* Open a sequential dataset */
        'LMOPEN  DATAID(&hFile) OPTION(&sOptions)'
        if rc <> 0 /* If dataset does not already exist... */
        then do /* Create sequential dataset then open it */
          'LMCLOSE DATAID(&hFile)'
          'LMFREE  DATAID(&hFile)'
          address TSO 'ALLOCATE DATASET('sFile') NEW CATALOG',
                      'SPACE(5,15) TRACKS RECFM(V,B)',
                      'LRECL(2048)',
                      'BLKSIZE(27990)' sAttrs
          if bOutput
          then do
            'LMINIT  DATAID(hFile) DATASET(&sFile) ENQ(EXCLU)'
            'LMOPEN  DATAID(&hFile) OPTION(&sOptions)'
          end
          else do
            'LMINIT  DATAID(hFile) DATASET(&sFile)'
            'LMOPEN  DATAID(&hFile) OPTION(INPUT)'
          end
        end
      end
      g.0OPTIONS.hFile = sOptions
      g.0rc = rc /* Return code from LMOPEN */
    end
    otherwise do
      if wordpos('OUTPUT',sOptions) > 0
      then junk = stream(sFile,'COMMAND','OPEN WRITE REPLACE')
      else junk = stream(sFile,'COMMAND','OPEN READ')
      hFile = sFile
      if stream(sFile,'STATUS') = 'READY'
      then g.0rc = 0
      else g.0rc = 4
    end
  end
return hFile

/*-------------------------------------------------------------------*
 * Read a line from the specified file
 *-------------------------------------------------------------------*/

getLine: procedure expose g.
  parse arg hFile
  sLine = ''
  select
    when g.0ENV = 'TSO' then do
      'LMGET DATAID(&hFile) MODE(INVAR)',
            'DATALOC(sLine) DATALEN(nLine) MAXLEN(32768)'
      g.0rc = rc
      sLine = strip(sLine,'TRAILING')
      if sLine = '' then sLine = ' '
    end
    otherwise do
      g.0rc = 0
      if chars(hFile) > 0
      then sLine = linein(hFile)
      else g.0rc = 4
    end
  end
return sLine

/*-------------------------------------------------------------------*
 * Append a line to the specified file
 *-------------------------------------------------------------------*/

putLine: procedure expose g.
  parse arg hFile,sLine
  select
    when g.0ENV = 'TSO' then do
      g.0LINES = g.0LINES + 1
      'LMPUT DATAID(&hFile) MODE(INVAR)',
            'DATALOC(sLine) DATALEN('length(sLine)')'
    end
    otherwise do
      junk = lineout(hFile,sLine)
      rc = 0
    end
  end
return rc

/*-------------------------------------------------------------------*
 * Close the specified file
 *-------------------------------------------------------------------*/

closeFile: procedure expose g.
  parse arg hFile
  rc = 0
  select
    when g.0ENV = 'TSO' then do
      if g.0MEMBER.hFile <> '', /* if its a PDS */
      & wordpos('OUTPUT',g.0OPTIONS.hFile) > 0 /* opened for output */
      then do
        parse value date('STANDARD') with yyyy +4 mm +2 dd +2
        parse var g.0STATS.hFile zlvers','zlmod','zlc4date
        zlcnorc  = min(g.0LINES,65535)   /* Number of lines   */
        nVer = right(zlvers,2,'0')right(zlmod,2,'0')  /* vvmm */
        nVer = right(nVer+1,4,'0')       /* vvmm + 1          */
        parse var nVer zlvers +2 zlmod +2
        if zlc4date = '0000/00/00'
        then zlc4date = yyyy'/'mm'/'dd   /* Creation date     */
        zlm4date = yyyy'/'mm'/'dd        /* Modification date */
        zlmtime  = time()                /* Modification time */
        zluser   = userid()              /* Modification user */
        'LMMREP DATAID(&hFile) MEMBER('g.0MEMBER.hFile') STATS(YES)'
      end
      'LMCLOSE DATAID(&hFile)'
      'LMFREE  DATAID(&hFile)'
    end
    otherwise do
      if stream(hFile,'COMMAND','CLOSE') = 'UNKNOWN'
      then rc = 0
      else rc = 4
    end
  end
return rc

/*REXX 2.0.0
Copyright (c) 2009-2020, Andrew J. Armstrong
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

/**********************************************************************
**                                                                   **
** ALL CODE BELOW THIS POINT BELONGS TO THE XML PARSER. YOU MUST     **
** APPEND IT TO ANY REXX SOURCE FILE THAT REQUIRES AN XML PARSING    **
** CAPABILITY. SINCE REXX HAS NO 'LIBRARY' FUNCTIONALITY, A WAY TO   **
** AVOID HAVING DIFFERENT VERSIONS OF THE PARSER IN EACH OF YOUR     **
** REXX PROCS IS TO DYNAMICALLY APPEND A CENTRAL VERSION TO EACH OF  **
** YOUR REXX PROCS BEFORE EXECUTION.                                 **
**                                                                   **
** THE EXACT PROCEDURE TO FOLLOW DEPENDS ON YOUR PLATFORM, BUT...    **
** TO HELP YOU DO THIS, I HAVE INCLUDED A REXX PRE-PROCESSOR CALLED  **
** REXXPP THAT CAN BE USED TO SEARCH FOR 'INCLUDE' DIRECTIVES AND    **
** REPLACE THEM WITH THE SPECIFIED FILE CONTENTS. IT HAS BEEN TESTED **
** ON TSO, AND ON WIN32 USING REGINA REXX VERSION 3.3.               **
**                                                                   **
**********************************************************************/

/*REXX*****************************************************************
**                                                                   **
** NAME     - PARSEXML                                               **
**                                                                   **
** FUNCTION - A Rexx XML parser. It is non-validating, so DTDs and   **
**            XML schemas are ignored. Ok, DTD entities are processed**
**            but that's all.                                        **
**                                                                   **
** USAGE    - 1. Initialize the parser by:                           **
**                                                                   **
**               call initParser [options...]                        **
**                                                                   **
**            2. Parse the XML file to build an in-memory model      **
**                                                                   **
**               returncode = parseFile('filename')                  **
**                ...or...                                           **
**               returncode = parseString('xml in a string')         **
**                                                                   **
**            3. Navigate the in-memory model with the DOM API. For  **
**               example:                                            **
**                                                                   **
**               say 'The document element is called',               **
**                                   getName(getDocumentElement())   **
**               say 'Children of the document element are:'         **
**               node = getFirstChild(getDocumentElement())          **
**               do while node <> ''                                 **
**                 if isElementNode(node)                            **
**                 then say 'Element node:' getName(node)            **
**                 else say '   Text node:' getText(node)            **
**                 node = getNextSibling(node)                       **
**               end                                                 **
**                                                                   **
**            4. Optionally, destroy the in-memory model:            **
**                                                                   **
**               call destroyParser                                  **
**                                                                   **
** INPUT    - An XML file containing:                                **
**              1. An optional XML prolog:                           **
**                 - 0 or 1 XML declaration:                         **
**                     <?xml version="1.0" encoding="..." ...?>      **
**                 - 0 or more comments, PIs, and whitespace:        **
**                     <!-- a comment -->                            **
**                     <?target string?>                             **
**                 - 0 or 1 document type declaration. Formats:      **
**                     <!DOCTYPE root SYSTEM "sysid">                **
**                     <!DOCTYPE root PUBLIC "pubid" SYSTEM "sysid"> **
**                     <!DOCTYPE root [internal dtd]>                **
**              2. An XML body:                                      **
**                 - 1 Document element containing 0 or more child   **
**                     elements. For example:                        **
**                     <doc attr1="value1" attr2="value2"...>        **
**                       Text of doc element                         **
**                       <child1 attr1="value1">                     **
**                         Text of child1 element                    **
**                       </child1>                                   **
**                       More text of doc element                    **
**                       <!-- an empty child element follows -->     **
**                       <child2/>                                   **
**                       Even more text of doc element               **
**                     </doc>                                        **
**                 - Elements may contain:                           **
**                   Unparsed character data:                        **
**                     <![CDATA[...unparsed data...]]>               **
**                   Entity references:                              **
**                     &name;                                        **
**                   Character references:                           **
**                     &#nnnnn;                                      **
**                     &#xXXXX;                                      **
**              3. An XML epilog (which is ignored):                 **
**                 - 0 or more comments, PIs, and whitespace.        **
**                                                                   **
** API      - The basic setup/teardown API calls are:                **
**                                                                   **
**            initParser [options]                                   **
**                Initialises the parser's global variables and      **
**                remembers any runtime options you specify. The     **
**                options recognized are:                            **
**                NOBLANKS - Suppress whitespace-only nodes          **
**                DEBUG    - Display some debugging info             **
**                DUMP     - Display the parse tree                  **
**                                                                   **
**            parseFile(filename)                                    **
**                Parses the XML data in the specified filename and  **
**                builds an in-memory model that can be accessed via **
**                the DOM API (see below).                           **
**                                                                   **
**            parseString(text)                                      **
**                Parses the XML data in the specified string.       **
**                                                                   **
**            destroyParser                                          **
**                Destroys the in-memory model and miscellaneous     **
**                global variables.                                  **
**                                                                   **
**          - In addition, the following utility API calls can be    **
**            used:                                                  **
**                                                                   **
**            removeWhitespace(text)                                 **
**                Returns the supplied text string but with all      **
**                whitespace characters removed, multiple spaces     **
**                replaced with single spaces, and leading and       **
**                trailing spaces removed.                           **
**                                                                   **
**            removeQuotes(text)                                     **
**                Returns the supplied text string but with any      **
**                enclosing apostrophes or double-quotes removed.    **
**                                                                   **
**            escapeText(text)                                       **
**                Returns the supplied text string but with special  **
**                characters encoded (for example, '<' becomes &lt;) **
**                                                                   **
**            toString(node)                                         **
**                Walks the document tree (beginning at the specified**
**                node) and returns a string in XML format.          **
**                                                                   **
** DOM API  - The DOM (ok, DOM-like) calls that you can use are      **
**            listed below:                                          **
**                                                                   **
**            Document query/navigation API calls                    **
**            -----------------------------------                    **
**                                                                   **
**            getRoot()                                              **
**                Returns the node number of the root node. This     **
**                can be used in calls requiring a 'node' argument.  **
**                In this implementation, getDocumentElement() and   **
**                getRoot() are (incorrectly) synonymous - this may  **
**                change, so you should use getDocumentElement()     **
**                in preference to getRoot().                        **
**                                                                   **
**            getDocumentElement()                                   **
**                Returns the node number of the document element.   **
**                The document element is the topmost element node.  **
**                You should use this in preference to getRoot()     **
**                (see above).                                       **
**                                                                   **
**            getName(node)                                          **
**                Returns the name of the specified node.            **
**                                                                   **
**            getNodeValue(node)                                     **
**            getText(node)                                          **
**                Returns the text content of an unnamed node. A     **
**                node without a name can only contain text. It      **
**                cannot have attributes or children.                **
**                                                                   **
**            getAttributeCount(node)                                **
**                Returns the number of attributes present on the    **
**                specified node.                                    **
**                                                                   **
**            getAttributeMap(node)                                  **
**                Builds a map of the attributes of the specified    **
**                node. The map can be accessed via the following    **
**                variables:                                         **
**                  g.0ATTRIBUTE.0 = The number of attributes mapped.**
**                  g.0ATTRIBUTE.n = The name of attribute 'n' (in   **
**                                   order of appearance). n > 0.    **
**                  g.0ATTRIBUTE.name = The value of the attribute   **
**                                   called 'name'.                  **
**                                                                   **
**            getAttributeName(node,n)                               **
**                Returns the name of the nth attribute of the       **
**                specified node (1 is first, 2 is second, etc).     **
**                                                                   **
**            getAttributeNames(node)                                **
**                Returns a space-delimited list of the names of the **
**                attributes of the specified node.                  **
**                                                                   **
**            getAttribute(node,name)                                **
**                Returns the value of the attribute called 'name' of**
**                the specified node.                                **
**                                                                   **
**            getAttribute(node,n)                                   **
**                Returns the value of the nth attribute of the      **
**                specified node (1 is first, 2 is second, etc).     **
**                                                                   **
**            setAttribute(node,name,value)                          **
**                Updates the value of the attribute called 'name'   **
**                of the specified node. If no attribute exists with **
**                that name, then one is created.                    **
**                                                                   **
**            setAttributes(node,name1,value1,name2,value2,...)      **
**                Updates the attributes of the specified node. Zero **
**                or more name/value pairs are be specified as the   **
**                arguments.                                         **
**                                                                   **
**            hasAttribute(node,name)                                **
**                Returns 1 if the specified node has an attribute   **
**                with the specified name, else 0.                   **
**                                                                   **
**            getParentNode(node)                                    **
**            getParent(node)                                        **
**                Returns the node number of the specified node's    **
**                parent. If the node number returned is 0, then the **
**                specified node is the root node.                   **
**                All nodes have a parent (except the root node).    **
**                                                                   **
**            getFirstChild(node)                                    **
**                Returns the node number of the specified node's    **
**                first child node.                                  **
**                                                                   **
**            getLastChild(node)                                     **
**                Returns the node number of the specified node's    **
**                last child node.                                   **
**                                                                   **
**            getChildNodes(node)                                    **
**            getChildren(node)                                      **
**                Returns a space-delimited list of node numbers of  **
**                the children of the specified node. You can use    **
**                this list to step through the children as follows: **
**                  children = getChildren(node)                     **
**                  say 'Node' node 'has' words(children) 'children' **
**                  do i = 1 to words(children)                      **
**                     child = word(children,i)                      **
**                     say 'Node' child 'is' getName(child)          **
**                  end                                              **
**                                                                   **
**            getChildrenByName(node,name)                           **
**                Returns a space-delimited list of node numbers of  **
**                the immediate children of the specified node which **
**                are called 'name'. Names are case-sensitive.       **
**                                                                   **
**            getElementsByTagName(node,name)                        **
**                Returns a space-delimited list of node numbers of  **
**                the descendants of the specified node which are    **
**                called 'name'. Names are case-sensitive.           **
**                                                                   **
**            getNextSibling(node)                                   **
**                Returns the node number of the specified node's    **
**                next sibling node. That is, the next node sharing  **
**                the same parent.                                   **
**                                                                   **
**            getPreviousSibling(node)                               **
**                Returns the node number of the specified node's    **
**                previous sibline node. That is, the previous node  **
**                sharing the same parent.                           **
**                                                                   **
**            getProcessingInstruction(name)                         **
**                Returns the value of the PI with the specified     **
**                target name.                                       **
**                                                                   **
**            getProcessingInstructionList()                         **
**                Returns a space-delimited list of the names of all **
**                PI target names.                                   **
**                                                                   **
**            getNodeType(node)                                      **
**                Returns a number representing the specified node's **
**                type. The possible values can be compared to the   **
**                following global variables:                        **
**                g.0ELEMENT_NODE                = 1                 **
**                g.0ATTRIBUTE_NODE              = 2                 **
**                g.0TEXT_NODE                   = 3                 **
**                g.0CDATA_SECTION_NODE          = 4                 **
**                g.0ENTITY_REFERENCE_NODE       = 5                 **
**                g.0ENTITY_NODE                 = 6                 **
**                g.0PROCESSING_INSTRUCTION_NODE = 7                 **
**                g.0COMMENT_NODE                = 8                 **
**                g.0DOCUMENT_NODE               = 9                 **
**                g.0DOCUMENT_TYPE_NODE          = 10                **
**                g.0DOCUMENT_FRAGMENT_NODE      = 11                **
**                g.0NOTATION_NODE               = 12                **
**                Note: as this exposes internal implementation      **
**                details, it is best not to use this routine.       **
**                Consider using isTextNode() etc instead.           **
**                                                                   **
**            isCDATA(node)                                          **
**                Returns 1 if the specified node is an unparsed     **
**                character data (CDATA) node, else 0. CDATA nodes   **
**                are used to contain content that you do not want   **
**                to be treated as XML data. For example, HTML data. **
**                                                                   **
**            isElementNode(node)                                    **
**                Returns 1 if the specified node is an element node,**
**                else 0.                                            **
**                                                                   **
**            isTextNode(node)                                       **
**                Returns 1 if the specified node is a text node,    **
**                else 0.                                            **
**                                                                   **
**            isCommentNode(node)                                    **
**                Returns 1 if the specified node is a comment node, **
**                else 0. Note: when a document is parsed, comment   **
**                nodes are ignored. This routine returns 1 iff a    **
**                comment node has been inserted into the in-memory  **
**                document tree by using createComment().            **
**                                                                   **
**            hasChildren(node)                                      **
**                Returns 1 if the specified node has one or more    **
**                child nodes, else 0.                               **
**                                                                   **
**            getDocType(doctype)                                    **
**                Gets the text of the <!DOCTYPE> prolog node.       **
**                                                                   **
**            Document creation/mutation API calls                   **
**            ------------------------------------                   **
**                                                                   **
**            createDocument(name)                                   **
**                Returns the node number of a new document node     **
**                with the specified name.                           **
**                                                                   **
**            createDocumentFragment(name)                           **
**                Returns the node number of a new document fragment **
**                node with the specified name.                      **
**                                                                   **
**            createElement(name)                                    **
**                Returns the node number of a new empty element     **
**                node with the specified name. An element node can  **
**                have child nodes.                                  **
**                                                                   **
**            createTextNode(data)                                   **
**                Returns the node number of a new text node. A text **
**                node can *not* have child nodes.                   **
**                                                                   **
**            createCDATASection(data)                               **
**                Returns the node number of a new Character Data    **
**                (CDATA) node. A CDATA node can *not* have child    **
**                nodes. CDATA nodes are used to contain content     **
**                that you do not want to be treated as XML data.    **
**                For example, HTML data.                            **
**                                                                   **
**            createComment(data)                                    **
**                Returns the node number of a new commend node.     **
**                A command node can *not* have child nodes.         **
**                                                                   **
**            appendChild(node,parent)                               **
**                Appends the specified node to the end of the list  **
**                of children of the specified parent node.          **
**                                                                   **
**            insertBefore(node,refnode)                             **
**                Inserts node 'node' before the reference node      **
**                'refnode'.                                         **
**                                                                   **
**            removeChild(node)                                      **
**                Removes the specified node from its parent and     **
**                returns its node number. The removed child is now  **
**                an orphan.                                         **
**                                                                   **
**            replaceChild(newnode,oldnode)                          **
**                Replaces the old child 'oldnode' with the new      **
**                child 'newnode' and returns the old child's node   **
**                number. The old child is now an orphan.            **
**                                                                   **
**            setAttribute(node,attrname,attrvalue)                  **
**                Adds or replaces the attribute called 'attrname'   **
**                on the specified node.                             **
**                                                                   **
**            removeAttribute(node,attrname)                         **
**                Removes the attribute called 'attrname' from the   **
**                specified node.                                    **
**                                                                   **
**            setDocType(doctype)                                    **
**                Sets the text of the <!DOCTYPE> prolog node.       **
**                                                                   **
**            cloneNode(node,[deep])                                 **
**                Creates a copy (a clone) of the specified node     **
**                and returns its node number. If deep = 1 then      **
**                all descendants of the specified node are also     **
**                cloned, else only the specified node and its       **
**                attributes are cloned.                             **
**                                                                   **
** NOTES    - 1. This parser creates global variables and so its     **
**               operation may be severely jiggered if you update    **
**               any of them accidentally (or on purpose). The       **
**               variables you should avoid updating yourself are:   **
**                                                                   **
**               g.0ATTRIBUTE.n                                      **
**               g.0ATTRIBUTE.name                                   **
**               g.0ATTRSOK                                          **
**               g.0DTD                                              **
**               g.0ENDOFDOC                                         **
**               g.0ENTITIES                                         **
**               g.0ENTITY.name                                      **
**               g.0FIRST.n                                          **
**               g.0LAST.n                                           **
**               g.0NAME.n                                           **
**               g.0NEXT.n                                           **
**               g.0NEXTID                                           **
**               g.0OPTION.name                                      **
**               g.0OPTIONS                                          **
**               g.0PARENT.n                                         **
**               g.0PI                                               **
**               g.0PI.name                                          **
**               g.0PREV.n                                           **
**               g.0PUBLIC                                           **
**               g.0ROOT                                             **
**               g.0STACK                                            **
**               g.0SYSTEM                                           **
**               g.0TEXT.n                                           **
**               g.0TYPE.n                                           **
**               g.0WHITESPACE                                       **
**               g.0XML                                              **
**               g.?XML                                              **
**               g.?XML.VERSION                                      **
**               g.?XML.ENCODING                                     **
**               g.?XML.STANDALONE                                   **
**                                                                   **
**            2. To reduce the incidence of name clashes, procedure  **
**               names that are not meant to be part of the public   **
**               API have been prefixed with '_'.                    **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** CONTRIBUTORS -                                                    **
**            Alessandro Battilani                                   **
**              <alessandro.battilani@bancaintesa.it>                **
**                                                                   **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top pls)       **
**            -------- --------------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**                         Ignore whitespace to fix parse error.     **
**            20070325 AJA Whitespace defaults to '090a0d'x.         **
**            20070323 AJA Added createDocumentFragment().           **
**                         Added isDocumentFragmentNode().           **
**                         Added isDocumentNode().                   **
**            20060915 AJA Added cloneNode().                        **
**                         Added deepClone().                        **
**                         Changed removeChild() to return the       **
**                         node number of the child instead of       **
**                         clearing it.                              **
**                         Changed replaceChild() to return the      **
**                         node number of the old child instead      **
**                         of clearing it.                           **
**            20060913 AJA Fixed bug in _resolveEntities().          **
**            20060808 AB  Added support for reading from a DD       **
**                         name when running IRXJCL on MVS.          **
**                         This change was contributed by            **
**                         Alessandro Battilani from Banca           **
**                         Intesa, Italy.                            **
**            20060803 AJA Fixed loop in getAttributeMap().          **
**            20051025 AJA Now checks parentage before adding a      **
**                         child node:                               **
**                         Fixed appendChild(id,parent)              **
**                         Fixed insertBefore(id,ref)                **
**            20051014 AJA Added alias routine names to more         **
**                         closely match the DOM specification.      **
**                         Specifically:                             **
**                         Added getNodeName()                       **
**                         Added getNodeValue()                      **
**                         Added getParentNode()                     **
**                         Added getChildNodes()                     **
**                         Added hasChildNodes()                     **
**                         Added getElementsByTagName()      .       **
**            20050919 AJA Added setAttributes helper routine.       **
**            20050914 AJA Added createComment and isComment.        **
**            20050913 AJA Added get/setDocType routines.            **
**            20050907 AJA Added _setDefaultEntities routine.        **
**            20050601 AJA Added '250d'x to whitespace for TSO.      **
**            20050514 AJA Removed getAttributes API call and        **
**                         reworked attribute processing.            **
**                         Added toString API call.                  **
**            20040706 AJA Added creation/modification support.      **
**            20031216 AJA Bugfix: _parseElement with no attrs       **
**                         causes crash.                             **
**            20031031 AJA Correctly parse '/' in attributes.        **
**                         Fixed entity resolution.                  **
**            20030912 AJA Bugfix: Initialize sXmlData first.        **
**                         Bugfix: Correctly parse a naked '>'       **
**                         present in an attribute value.            **
**                         Enhancement: DUMP option now displays     **
**                         first part of each text node.             **
**            20030901 AJA Intial version.                           **
**                                                                   **
**********************************************************************/

  parse source . . sSourceFile .
  parse value sourceline(1) with . sVersion
  say 'Rexx XML Parser' sVersion
  say 'You cannot invoke this rexx by itself!'
  say
  say 'This rexx is a collection of subroutines to be called'
  say 'from your own rexx procedures. You should either:'
  say '  - Append this procedure to your own rexx procedure,'
  say '    or,'
  say '  - Append the following line to your rexx:'
  say '    /* INCLUDE' sSourceFile '*/'
  say '    ...and run the rexx preprocessor:'
  say '    rexxpp myrexx myrexxpp'
  say '    This will create myrexxpp by appending this file to myrexx'
exit

/*-------------------------------------------------------------------*
 * Set up global variables for the parser
 *-------------------------------------------------------------------*/

initParser: procedure expose g.
  parse arg sOptions
  g. = '' /* Note: stuffs up caller who may have set g. variables */
  g.0OPTIONS = translate(sOptions)
  sOptions = 'DEBUG DUMP NOBLANKS'
  do i = 1 to words(sOptions)
    sOption = word(sOptions,i)
    g.0OPTION.sOption = wordpos(sOption,g.0OPTIONS) > 0
  end

  parse source sSystem sInvocation sSourceFile
  select
    when sSystem = 'WIN32'  then g.0WHITESPACE = '090a0d'x
    when sSystem = 'TSO'    then g.0WHITESPACE = '05250d'x
    otherwise                    g.0WHITESPACE = '090a0d'x /*20070325*/
  end

  g.0LEADERS = '_:ABCDEFGHIJKLMNOPQRSTUVWXYZ' ||,
                 'abcdefghijklmnopqrstuvwxyz'
  g.0OTHERS  = g.0LEADERS'.-0123456789'

  call _setDefaultEntities

  /* Not all of the following node types are used... */
  g.0ELEMENT_NODE            =  1; g.0NODETYPE.1 = 'Element'
  g.0ATTRIBUTE_NODE          =  2; g.0NODETYPE.2 = 'Attribute'
  g.0TEXT_NODE               =  3; g.0NODETYPE.3 = 'Text'
  g.0CDATA_SECTION_NODE      =  4; g.0NODETYPE.4 = 'CDATA Section'
  g.0ENTITY_REFERENCE_NODE   =  5     /* NOT USED */
  g.0ENTITY_NODE             =  6     /* NOT USED */
  g.0PROCESSING_INSTRUCTION_NODE = 7  /* NOT USED */
  g.0COMMENT_NODE            =  8; g.0NODETYPE.8 = 'Comment'
  g.0DOCUMENT_NODE           =  9; g.0NODETYPE.9 = 'Document'
  g.0DOCUMENT_TYPE_NODE      = 10    /* NOT USED */
  g.0DOCUMENT_FRAGMENT_NODE  = 11; g.0NODETYPE.11 = 'Document Fragment'
  g.0NOTATION_NODE           = 12    /* NOT USED */




  g.0ENDOFDOC = 0
return

/*-------------------------------------------------------------------*
 * Clean up parser
 *-------------------------------------------------------------------*/

destroyParser: procedure expose g.
  /* Note: it would be easy to just "drop g.", but this could
     possibly stuff up the caller who may be using other
     "g." variables...
     todo: revisit this one (parser may have to 'own' g. names)
  */
  drop g.?XML g.0ROOT g.0SYSTEM g.0PUBLIC g.0DTD
  do i = 1 to words(g.0PI)
    sName = word(g.0PI,i)
    drop g.0PI.sName
  end
  drop g.0PI
  do i = 1 to words(g.0ENTITIES)
    sName = word(g.0ENTITIES,i)
    drop g.0ENTITY.sName
  end
  drop g.0ENTITIES
  call _setDefaultEntities
  if datatype(g.0NEXTID,'WHOLE')
  then do
    do i = 1 to g.0NEXTID
      drop g.0PARENT.i g.0FIRST.i g.0LAST.i g.0PREV.i,
           g.0NEXT.i g.0NAME.i g.0TEXT.i
    end
  end
  drop g.0NEXTID g.0STACK g.0ENDOFDOC
return


/*-------------------------------------------------------------------*
 * Read a file into a string
 *-------------------------------------------------------------------*/

parseFile: procedure expose g.
  parse arg sFile
  parse source sSystem sInvocation sSourceFile . . . sInitEnv .
  sXmlData = ''
  select
    when sSystem = 'TSO' & sInitEnv = 'TSO' then do
      /* sFile is a dataset name */
      address TSO
      junk = OUTTRAP('junk.') /* Trap and discard messages */
      'ALLOCATE DD(INPUT) DSN('sFile')'
      'EXECIO * DISKR INPUT (FINIS'
      'FREE DD(INPUT)'
      address
      do queued()
        parse pull sLine
        sXmlData = sXmlData || sLine
      end
      junk = OUTTRAP('OFF')
    end
    when sSystem = 'TSO' & sInitEnv = 'MVS' then do
      /* sFile is a DD name */
      address MVS 'EXECIO * DISKR' sFile '(FINIS'
      do queued()
        parse pull sLine
        sXmlData = sXmlData || sLine
      end
    end
    otherwise do
      sXmlData = charin(sFile,,chars(sFile))
    end
  end
return parseString(sXmlData)

/*-------------------------------------------------------------------*
 * Parse a string containing XML
 *-------------------------------------------------------------------*/

parseString: procedure expose g.
  parse arg g.0XML
  call _parseXmlDecl
  do while pos('<',g.0XML) > 0
    parse var g.0XML sLeft'<'sData
    select
      when left(sData,1) = '?'         then call _parsePI      sData
      when left(sData,9) = '!DOCTYPE ' then call _parseDocType sData
      when left(sData,3) = '!--'       then call _parseComment sData
      otherwise                             call _parseElement sData
    end
  end
return 0

/*-------------------------------------------------------------------*
 * <?xml version="1.0" encoding="..." ...?>
 *-------------------------------------------------------------------*/

_parseXmlDecl: procedure expose g.
  if left(g.0XML,6) = '<?xml '
  then do
    parse var g.0XML '<?xml 'sXMLDecl'?>'g.0XML
    g.?xml = space(sXMLDecl)
    sTemp = _getNormalizedAttributes(g.?xml)
    parse var sTemp 'version='g.?xml.version'ff'x
    parse var sTemp 'encoding='g.?xml.encoding'ff'x
    parse var sTemp 'standalone='g.?xml.standalone'ff'x
  end
return

/*-------------------------------------------------------------------*
 * <?target string?>
 *-------------------------------------------------------------------*/

_parsePI: procedure expose g.
  parse arg '?'sProcessingInstruction'?>'g.0XML
  call _setProcessingInstruction sProcessingInstruction
return

/*-------------------------------------------------------------------*
 * <!DOCTYPE root SYSTEM "sysid">
 * <!DOCTYPE root SYSTEM "sysid" [internal dtd]>
 * <!DOCTYPE root PUBLIC "pubid" "sysid">
 * <!DOCTYPE root PUBLIC "pubid" "sysid" [internal dtd]>
 * <!DOCTYPE root [internal dtd]>
 *-------------------------------------------------------------------*/

_parseDocType: procedure expose g.
  parse arg '!DOCTYPE' sDocType'>'
  if g.0ROOT <> ''
  then call _abort 'XML002E Multiple "<!DOCTYPE" declarations'
  if pos('[',sDocType) > 0
  then do
    parse arg '!DOCTYPE' sDocType'['g.0DTD']>'g.0XML
    parse var sDocType g.0ROOT sExternalId
    if sExternalId <> '' then call _parseExternalId sExternalId
    g.0DTD = strip(g.0DTD)
    call _parseDTD g.0DTD
  end
  else do
    parse arg '!DOCTYPE' g.0ROOT sExternalId'>'g.0XML
    if sExternalId <> '' then call _parseExternalId sExternalId
  end
  g.0ROOT = strip(g.0ROOT)
return

/*-------------------------------------------------------------------*
 * SYSTEM "sysid"
 * PUBLIC "pubid" "sysid"
 *-------------------------------------------------------------------*/

_parseExternalId: procedure expose g.
  parse arg sExternalIdType .
  select
    when sExternalIdType = 'SYSTEM' then do
      parse arg . g.0SYSTEM
      g.0SYSTEM = removeQuotes(g.0SYSTEM)
    end
    when sExternalIdType = 'PUBLIC' then do
      parse arg . g.0PUBLIC g.0SYSTEM
      g.0PUBLIC = removeQuotes(g.0PUBLIC)
      g.0SYSTEM = removeQuotes(g.0SYSTEM)
    end
    otherwise do
       parse arg sExternalEntityDecl
       call _abort 'XML003E Invalid external entity declaration:',
                   sExternalEntityDecl
    end
  end
return


/*-------------------------------------------------------------------*
 * <!ENTITY name "value">
 * <!ENTITY name SYSTEM "sysid">
 * <!ENTITY name PUBLIC "pubid" "sysid">
 * <!ENTITY % name pedef>
 * <!ELEMENT elementname contentspec>
 * <!ATTLIST elementname attrname attType DefaultDecl ...>
 * <!NOTATION name notationdef>
 *-------------------------------------------------------------------*/

_parseDTD: procedure expose g.
  parse arg sDTD
  do while pos('<!',sDTD) > 0
    parse var sDTD '<!'sDecl sName sValue'>'sDTD
    select
      when sDecl = 'ENTITY' then do
        parse var sValue sWord1 .
        select
          when sName = '%'       then nop
          when sWord1 = 'SYSTEM' then nop
          when sWord1 = 'PUBLIC' then nop
          otherwise do
            sValue = _resolveEntities(removeQuotes(sValue))
            call _setEntity sName,sValue
          end
        end
      end
      otherwise nop /* silently ignore other possibilities for now */
    end
  end
return

/*-------------------------------------------------------------------*
 * <!-- comment -->
 *-------------------------------------------------------------------*/

_parseComment: procedure expose g.
  parse arg sComment'-->'g.0XML
  /* silently ignore comments */
return

/*-------------------------------------------------------------------*
 * <tag attr1="value1" attr2="value2" ...>...</tag>
 * <tag attr1="value1" attr2="value2" .../>
 *-------------------------------------------------------------------*/

_parseElement: procedure expose g.
  parse arg sXML

  if g.0ENDOFDOC
  then call _abort 'XML004E Only one top level element is allowed.',
                  'Found:' subword(g.0XML,1,3)
  call _startDocument

  g.0XML = '<'sXML
  do while pos('<',g.0XML) > 0 & \g.0ENDOFDOC
    parse var g.0XML sLeft'<'sBetween'>'g.0XML

    if length(sLeft) > 0
    then call _characters sLeft

    if g.0OPTION.DEBUG
    then say g.0STACK sBetween

    if left(sBetween,8) = '![CDATA['
    then do
      g.0XML = sBetween'>'g.0XML            /* ..back it out! */
      parse var g.0XML '![CDATA['sBetween']]>'g.0XML
      call _characterData sBetween
    end
    else do
      sBetween = removeWhiteSpace(sBetween)                /*20090822*/
      select
        when left(sBetween,3) = '!--' then do    /* <!-- comment --> */
          if right(sBetween,2) <> '--'
          then do  /* backup a bit and look for end-of-comment */
            g.0XML = sBetween'>'g.0XML
            if pos('-->',g.0XML) = 0
            then call _abort 'XML005E End of comment missing after:',
                            '<'g.0XML
            parse var g.0XML sComment'-->'g.0XML
          end
        end
        when left(sBetween,1) = '?' then do    /* <?target string?> */
          parse var sBetween '?'sProcessingInstruction'?'
          call _setProcessingInstruction sProcessingInstruction
        end
        when left(sBetween,1) = '/' then do    /* </tag> */
          call _endElement substr(sBetween,2)   /* tag */
        end
        when  right(sBetween,1) = '/'  /* <tag ...attrs.../> */
        then do
          parse var sBetween sTagName sAttrs
          if length(sAttrs) > 0                            /*20031216*/
          then sAttrs = substr(sAttrs,1,length(sAttrs)-1)  /*20031216*/
          else parse var sTagName sTagName'/'     /* <tag/>  20031216*/
          sAttrs = _getNormalizedAttributes(sAttrs)
          call _startElement sTagName sAttrs
          call _endElement sTagName
        end
        otherwise do              /* <tag ...attrs ...> ... </tag>  */
          parse var sBetween sTagName sAttrs
          sAttrs = _getNormalizedAttributes(sAttrs)
          if g.0ATTRSOK
          then do
            call _startElement sTagName sAttrs
          end
          else do /* back up a bit and look for the real end of tag */
            g.0XML = '<'sBetween'&gt;'g.0XML
            if pos('>',g.0XML) = 0
            then call _abort 'XML006E Missing end tag for:' sTagName
            /* reparse on next cycle avoiding premature '>'...*/
          end
        end
      end
    end
  end

  call _endDocument
return

_startDocument: procedure expose g.
  g.0NEXTID = 0
  g.0STACK = 0
return

_startElement:  procedure expose g.
  parse arg sTagName sAttrs
  id = _getNextId()
  call _updateLinkage id
  g.0NAME.id = sTagName
  g.0TYPE.id = g.0ELEMENT_NODE
  call _addAttributes id,sAttrs
  cid = _pushElement(id)
return

_updateLinkage: procedure expose g.
  parse arg id
  parent = _peekElement()
  g.0PARENT.id = parent
  parentsLastChild = g.0LAST.parent
  g.0NEXT.parentsLastChild = id
  g.0PREV.id = parentsLastChild
  g.0LAST.parent = id
  if g.0FIRST.parent = ''
  then g.0FIRST.parent = id
return

_characterData: procedure expose g.
  parse arg sChars
  id = _getNextId()
  call _updateLinkage id
  g.0TEXT.id = sChars
  g.0TYPE.id = g.0CDATA_SECTION_NODE
return

_characters: procedure expose g.
  parse arg sChars
  sText = _resolveEntities(sChars)
  if g.0OPTION.NOBLANKS & removeWhitespace(sText) = ''
  then return
  id = _getNextId()
  call _updateLinkage id
  g.0TEXT.id = sText
  g.0TYPE.id = g.0TEXT_NODE
return

_endElement: procedure expose g.
  parse arg sTagName
  id = _popElement()
  g.0ENDOFDOC = id = 1
  if sTagName == g.0NAME.id
  then nop
  else call _abort,
           'XML007E Expecting </'g.0NAME.id'> but found </'sTagName'>'
return

_endDocument: procedure expose g.
  id = _peekElement()
  if id <> 0
  then call _abort 'XML008E End of document tag missing: 'id getName(id)
  if g.0ROOT <> '' & g.0ROOT <> getName(getRoot())
  then call _abort 'XML009E Root element name "'getName(getRoot())'"',
                  'does not match DTD root "'g.0ROOT'"'

  if g.0OPTION.DUMP
  then call _displayTree
return

_displayTree: procedure expose g.
  say   right('',4),
        right('',4),
        left('',12),
        right('',6),
        '--child--',
        '-sibling-',
        'attribute'
  say   right('id',4),
        right('type',4),
        left('name',12),
        right('parent',6),
        right('1st',4),
        right('last',4),
        right('prev',4),
        right('next',4),
        right('1st',4),
        right('last',4)
  do id = 1 to g.0NEXTID
    if g.0PARENT.id <> '' | id = 1 /* skip orphans */
    then do
      select
        when g.0TYPE.id = g.0CDATA_SECTION_NODE then sName = '#CDATA'
        when g.0TYPE.id = g.0TEXT_NODE          then sName = '#TEXT'
        otherwise                                    sName = g.0NAME.id
      end
      say right(id,4),
          right(g.0TYPE.id,4),
          left(sName,12),
          right(g.0PARENT.id,6),
          right(g.0FIRST.id,4),
          right(g.0LAST.id,4),
          right(g.0PREV.id,4),
          right(g.0NEXT.id,4),
          right(g.0FIRSTATTR.id,4),
          right(g.0LASTATTR.id,4),
          left(removeWhitespace(g.0TEXT.id),19)
    end
  end
return

_pushElement: procedure expose g.
  parse arg id
  g.0STACK = g.0STACK + 1
  nStackDepth = g.0STACK
  g.0STACK.nStackDepth = id
return id

_popElement: procedure expose g.
  n = g.0STACK
  if n = 0
  then id = 0
  else do
    id = g.0STACK.n
    g.0STACK = g.0STACK - 1
  end
return id

_peekElement: procedure expose g.
  n = g.0STACK
  if n = 0
  then id = 0
  else id = g.0STACK.n
return id

_getNextId: procedure expose g.
  g.0NEXTID = g.0NEXTID + 1
return g.0NEXTID

_addAttributes: procedure expose g.
  parse arg id,sAttrs
  do while pos('ff'x,sAttrs) > 0
    parse var sAttrs sAttrName'='sAttrValue 'ff'x sAttrs
    sAttrName = removeWhitespace(sAttrName)
    call _addAttribute id,sAttrName,sAttrValue
  end
return

_addAttribute: procedure expose g.
  parse arg id,sAttrName,sAttrValue
  aid = _getNextId()
  g.0TYPE.aid = g.0ATTRIBUTE_NODE
  g.0NAME.aid = sAttrName
  g.0TEXT.aid = _resolveEntities(sAttrValue)
  g.0PARENT.aid = id
  g.0NEXT.aid = ''
  g.0PREV.aid = ''
  if g.0FIRSTATTR.id = '' then g.0FIRSTATTR.id = aid
  if g.0LASTATTR.id <> ''
  then do
    lastaid = g.0LASTATTR.id
    g.0NEXT.lastaid = aid
    g.0PREV.aid = lastaid
  end
  g.0LASTATTR.id = aid
return

/*-------------------------------------------------------------------*
 * Resolve attributes to an internal normalized form:
 *   name1=value1'ff'x name2=value2'ff'x ...
 * This makes subsequent parsing of attributes easier.
 * Note: this design may fail for certain UTF-8 content
 *-------------------------------------------------------------------*/

_getNormalizedAttributes: procedure expose g.
  parse arg sAttrs
  g.0ATTRSOK = 0
  sNormalAttrs = ''
  parse var sAttrs sAttr'='sAttrs
  do while sAttr <> ''
    sAttr = removeWhitespace(sAttr)
    select
      when left(sAttrs,1) = '"' then do
        if pos('"',sAttrs,2) = 0 /* if no closing "   */
        then return ''           /* then not ok       */
        parse var sAttrs '"'sAttrValue'"'sAttrs
      end
      when left(sAttrs,1) = "'" then do
        if pos("'",sAttrs,2) = 0 /* if no closing '   */
        then return ''           /* then not ok       */
        parse var sAttrs "'"sAttrValue"'"sAttrs
      end
      otherwise return ''        /* no opening ' or " */
    end
    sAttrValue = removeWhitespace(sAttrValue)
    sNormalAttrs = sNormalAttrs sAttr'='sAttrValue'ff'x
    parse var sAttrs sAttr'='sAttrs
  end
  g.0ATTRSOK = 1
  /* Note: always returns a leading blank and is required by
    this implementation */
return _resolveEntities(sNormalAttrs)


/*-------------------------------------------------------------------*
 *  entityref  := '&' entityname ';'
 *  entityname := ('_',':',letter) (letter,digit,'.','-','_',':')*
 *-------------------------------------------------------------------*/


_resolveEntities: procedure expose g.
  parse arg sText
  if pos('&',sText) > 0
  then do
    sNewText = ''
    do while pos('&',sText) > 0
      parse var sText sLeft'&'sEntityRef
      if pos(left(sEntityRef,1),'#'g.0LEADERS) > 0
      then do
        n = verify(sEntityRef,g.0OTHERS,'NOMATCH',2)
        if n > 1
        then do
          if substr(sEntityRef,n,1) = ';'
          then do
            sEntityName = left(sEntityRef,n-1)
            sEntity = _getEntity(sEntityName)
            sNewText = sNewText || sLeft || sEntity
            sText = substr(sEntityRef,n+1)
          end
          else do
            sNewText = sNewText || sLeft'&'
            sText = sEntityRef
          end
        end
        else do
          sNewText = sNewText || sLeft'&'
          sText = sEntityRef
        end
      end
      else do
        sNewText = sNewText || sLeft'&'
        sText = sEntityRef
      end
    end
    sText = sNewText || sText
  end
return sText

/*-------------------------------------------------------------------*
 * &entityname;
 * &#nnnnn;
 * &#xXXXX;
 *-------------------------------------------------------------------*/

_getEntity: procedure expose g.
  parse arg sEntityName
  if left(sEntityName,1) = '#' /* #nnnnn  OR  #xXXXX */
  then sEntity = _getCharacterEntity(sEntityName)
  else sEntity = _getStringEntity(sEntityName)
return sEntity

/*-------------------------------------------------------------------*
 * &#nnnnn;
 * &#xXXXX;
 *-------------------------------------------------------------------*/

_getCharacterEntity: procedure expose g.
  parse arg sEntityName
  if substr(sEntityName,2,1) = 'x'
  then do
    parse arg 3 xEntity
    if datatype(xEntity,'XADECIMAL')
    then sEntity = x2c(xEntity)
    else call _abort,
              'XML010E Invalid hexadecimal character reference: ',
              '&'sEntityName';'
  end
  else do
    parse arg 2 nEntity
    if datatype(nEntity,'WHOLE')
    then sEntity = d2c(nEntity)
    else call _abort,
              'XML011E Invalid decimal character reference:',
              '&'sEntityName';'
  end
return sEntity

/*-------------------------------------------------------------------*
 * &entityname;
 *-------------------------------------------------------------------*/

_getStringEntity: procedure expose g.
  parse arg sEntityName
  if wordpos(sEntityName,g.0ENTITIES) = 0
  then call _abort 'XML012E Unable to resolve entity &'sEntityName';'
  sEntity = g.0ENTITY.sEntityName
return sEntity

_setDefaultEntities: procedure expose g.
  g.0ENTITIES = ''
  g.0ESCAPES = '<>&"' || "'"
  sEscapes = 'lt gt amp quot apos'
  do i = 1 to length(g.0ESCAPES)
    c = substr(g.0ESCAPES,i,1)
    g.0ESCAPE.c = word(sEscapes,i)
  end
  call _setEntity 'amp','&'
  call _setEntity 'lt','<'
  call _setEntity 'gt','>'
  call _setEntity 'apos',"'"
  call _setEntity 'quot','"'
return

_setEntity: procedure expose g.
  parse arg sEntityName,sValue
  if wordpos(sEntityName,g.0ENTITIES) = 0
  then g.0ENTITIES = g.0ENTITIES sEntityName
  g.0ENTITY.sEntityName = sValue
return

_setProcessingInstruction: procedure expose g.
  parse arg sTarget sInstruction
  if wordpos(sTarget,g.0PI) = 0
  then g.0PI = g.0PI sTarget
  g.0PI.sTarget = strip(sInstruction)
return

_abort: procedure expose g.
  parse arg sMsg
  say 'ABORT:' sMsg
  call destroyParser
exit 16

_clearNode: procedure expose g.
  parse arg id
  g.0NAME.id       = '' /* The node's name */
  g.0PARENT.id     = '' /* The node's parent */
  g.0FIRST.id      = '' /* The node's first child */
  g.0LAST.id       = '' /* The node's last child */
  g.0NEXT.id       = '' /* The node's next sibling */
  g.0PREV.id       = '' /* The node's previous sibling */
  g.0TEXT.id       = '' /* The node's text content */
  g.0TYPE.id       = '' /* The node's type */
  g.0FIRSTATTR.id  = '' /* The node's first attribute */
  g.0LASTATTR.id   = '' /* The node's last attribute */
return

/*-------------------------------------------------------------------*
 * Utility API
 *-------------------------------------------------------------------*/

removeWhitespace: procedure expose g.
  parse arg sData
return space(translate(sData,'',g.0WHITESPACE))

removeQuotes: procedure expose g.
  parse arg sValue
  c = left(sValue,1)
  select
    when c = '"' then parse var sValue '"'sValue'"'
    when c = "'" then parse var sValue "'"sValue"'"
    otherwise nop
  end
return sValue

/*-------------------------------------------------------------------*
 * Document Object Model ;-) API
 *-------------------------------------------------------------------*/

getRoot: procedure expose g. /* DEPRECATED */
return 1

getDocumentElement: procedure expose g.
return 1

getName: getNodeName: procedure expose g.
  parse arg id
return g.0NAME.id

getText: getNodeValue: procedure expose g.
  parse arg id
return g.0TEXT.id

getNodeType: procedure expose g.
  parse arg id
return g.0TYPE.id

isElementNode: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0ELEMENT_NODE

isTextNode: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0TEXT_NODE

isCommentNode: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0COMMENT_NODE

isCDATA: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0CDATA_SECTION_NODE

isDocumentNode: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0DOCUMENT_NODE

isDocumentFragmentNode: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0DOCUMENT_FRAGMENT_NODE

/**
 * This is similar to the DOM API's NamedNodeMap concept, except that
 * the returned structure is built in global variables (so calling
 * it a second time will destroy the structure built on the first
 * call). The other difference is that you can access the attributes
 * by name or ordinal number. For example, g.0ATTRIBUTE.2 is the value
 * of the second attribute. If the second attribute was called 'x',
 * then you could also access it by g.0ATTRIBUTE.x (as long as x='x')
 * Note, g.0ATTRIBUTE.0 will always contain a count of the number of
 * attributes in the map.
 */
getAttributeMap: procedure expose g.
  parse arg id
  if datatype(g.0ATTRIBUTE.0,'WHOLE')  /* clear any existing map */
  then do
    do i = 1 to g.0ATTRIBUTE.0
      sName = g.0ATTRIBUTE.i
      drop g.0ATTRIBUTE.sName g.0ATTRIBUTE.i
    end
  end
  g.0ATTRIBUTE.0 = 0
  if \_canHaveAttributes(id) then return
  aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
  do i = 1 while aid <> ''
    sName = g.0NAME.aid
    sValue = g.0TEXT.aid
    g.0ATTRIBUTE.0 = i
    g.0ATTRIBUTE.i = sName
    g.0ATTRIBUTE.sName = sValue
    aid = g.0NEXT.aid /* id of next attribute */
  end
return

getAttributeCount: procedure expose g.
  parse arg id
  nAttributeCount = 0
  if _canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
    do while aid <> ''
      nAttributeCount = nAttributeCount + 1
      aid = g.0NEXT.aid /* id of next attribute */
    end
  end
return nAttributeCount

getAttributeNames: procedure expose g.
  parse arg id
  sNames = ''
  if _canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
    do while aid <> ''
      sNames = sNames g.0NAME.aid
      aid = g.0NEXT.aid /* id of next attribute */
    end
  end
return strip(sNames)

getAttribute: procedure expose g.
  parse arg id,sAttrName
  sValue = ''
  if _canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
    if aid <> ''
    then do
      n = 1
      do while aid <> '' & (g.0NAME.aid <> sAttrName & n <> sAttrName)
        aid = g.0NEXT.aid
        n = n + 1
      end
      if g.0NAME.aid = sAttrName | n = sAttrName
      then sValue = g.0TEXT.aid
    end
  end
return sValue

getAttributeName: procedure expose g.
  parse arg id,n
  sName = ''
  if _canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
    if aid <> ''
    then do
      do i = 1 while aid <> '' & i < n
        aid = g.0NEXT.aid
      end
      if i = n then sName = g.0NAME.aid
    end
  end
return sName

hasAttribute: procedure expose g.
  parse arg id,sAttrName
  bHasAttribute = 0
  if _canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id
    if aid <> ''
    then do
      do while aid <> '' & g.0NAME.aid <> sAttrName
        aid = g.0NEXT.aid
      end
      bHasAttribute = g.0NAME.aid = sAttrName
    end
  end
return bHasAttribute

_canHaveAttributes: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0ELEMENT_NODE |,
       g.0TYPE.id = g.0DOCUMENT_NODE |,
       g.0TYPE.id = g.0DOCUMENT_FRAGMENT_NODE

_canHaveChildren: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0ELEMENT_NODE |,
       g.0TYPE.id = g.0DOCUMENT_NODE |,
       g.0TYPE.id = g.0DOCUMENT_FRAGMENT_NODE

getParent: getParentNode: procedure expose g.
  parse arg id
return g.0PARENT.id

getFirstChild: procedure expose g.
  parse arg id
return g.0FIRST.id

getLastChild: procedure expose g.
  parse arg id
return g.0LAST.id

getChildren: getChildNodes: procedure expose g.
  parse arg id
  ids = ''
  id = getFirstChild(id)
  do while id <> ''
    ids = ids id
    id = getNextSibling(id)
  end
return strip(ids)

getChildrenByName: procedure expose g.
  parse arg id,sName
  ids = ''
  id = getFirstChild(id)
  do while id <> ''
    if getName(id) = sName
    then ids = ids id
    id = getNextSibling(id)
  end
return strip(ids)

getElementsByTagName: procedure expose g.
  parse arg id,sName
  ids = ''
  id = getFirstChild(id)
  do while id <> ''
    if getName(id) = sName
    then ids = ids id
    ids = ids getElementsByTagName(id,sName)
    id = getNextSibling(id)
  end
return space(ids)

getNextSibling: procedure expose g.
  parse arg id
return g.0NEXT.id

getPreviousSibling: procedure expose g.
  parse arg id
return g.0PREV.id

getProcessingInstruction: procedure expose g.
  parse arg sTarget
return g.0PI.sTarget

getProcessingInstructionList: procedure expose g.
return g.0PI

hasChildren: hasChildNodes: procedure expose g.
  parse arg id
return g.0FIRST.id <> ''

createDocument: procedure expose g.
  parse arg sName
  if sName = ''
  then call _abort,
            'XML013E Tag name omitted:',
            'createDocument('sName')'
  call destroyParser
  g.0NEXTID = 0
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0DOCUMENT_NODE /* 20070323 */
  g.0NAME.id = sName
  g.0PARENT.id = 0
return id

createDocumentFragment: procedure expose g. /* 20070323 */
  parse arg sName
  if sName = ''
  then call _abort,
            'XML014E Tag name omitted:',
            'createDocumentFragment('sName')'
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0DOCUMENT_FRAGMENT_NODE
  g.0NAME.id = sName
  g.0PARENT.id = 0
return id

createElement: procedure expose g.
  parse arg sName
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0ELEMENT_NODE
  g.0NAME.id = sName
return id

createCDATASection: procedure expose g.
  parse arg sCharacterData
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0CDATA_SECTION_NODE
  g.0TEXT.id = sCharacterData
return id

createTextNode: procedure expose g.
  parse arg sData
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0TEXT_NODE
  g.0TEXT.id = sData
return id

appendChild: procedure expose g.
  parse arg id, parent
  if \_canHaveChildren(parent)
  then call _abort,
            'XML015E' g.0NODETYPE.parent 'node cannot have children:',
            'appendChild('id','parent')'
  if g.0PARENT.id = ''
  then g.0PARENT.id = parent
  else call _abort,
            'XML016E Node <'getNodeName(id)'> is already a child',
            'of <'getNodeName(g.0PARENT.id)'>:',
            'appendChild('id','parent')'
  parentsLastChild = g.0LAST.parent
  g.0NEXT.parentsLastChild = id
  g.0PREV.id = parentsLastChild
  g.0LAST.parent = id
  if g.0FIRST.parent = ''
  then g.0FIRST.parent = id
return

insertBefore: procedure expose g.
  parse arg id, ref
  parent = g.0PARENT.ref
  if \_canHaveChildren(parent)
  then call _abort,
            'XML017E' g.0NODETYPE.parent 'node cannot have children:',
            'insertBefore('id','ref')'
  if g.0PARENT.id = ''
  then g.0PARENT.id = parent
  else call _abort,
            'XML018E Node <'getNodeName(id)'> is already a child',
            'of <'getNodeName(g.0PARENT.id)'>:',
            'insertBefore('id','ref')'
  g.0NEXT.id = ref
  oldprev = g.0PREV.ref
  g.0PREV.ref = id
  g.0NEXT.oldprev = id
  g.0PREV.id = oldprev
  if g.0FIRST.parent = ref
  then g.0FIRST.parent = id
return

removeChild: procedure expose g.
  parse arg id
  parent = g.0PARENT.id
  if \_canHaveChildren(parent)
  then call _abort,
            'XML019E' g.0NODETYPE.parent 'node cannot have children:',
            'removeChild('id')'
  next = g.0NEXT.id
  prev = g.0PREV.id
  g.0NEXT.prev = next
  g.0PREV.next = prev
  if g.0FIRST.parent = id
  then g.0FIRST.parent = next
  if g.0LAST.parent = id
  then g.0LAST.parent = prev
  g.0PARENT.id = ''
  g.0NEXT.id = ''
  g.0PREV.id = ''
return id

replaceChild: procedure expose g.
  parse arg id, extant
  parent = g.0PARENT.extant
  if \_canHaveChildren(parent)
  then call _abort,
            'XML020E' g.0NODETYPE.parent 'node cannot have children:',
            'replaceChild('id','extant')'
  g.0PARENT.id = parent
  g.0NEXT.id = g.0NEXT.extant
  g.0PREV.id = g.0PREV.extant
  if g.0FIRST.parent = extant
  then g.0FIRST.parent = id
  if g.0LAST.parent = extant
  then g.0LAST.parent = id
  g.0PARENT.extant = ''
  g.0NEXT.extant = ''
  g.0PREV.extant = ''
return extant

setAttribute: procedure expose g.
  parse arg id,sAttrName,sValue
  if \_canHaveAttributes(id)
  then call _abort,
            'XML021E' g.0NODETYPE.id 'node cannot have attributes:',
            'setAttribute('id','sAttrName','sValue')'
  aid = g.0FIRSTATTR.id
  do while aid <> '' & g.0NAME.aid <> sAttrName
    aid = g.0NEXT.aid
  end
  if aid <> '' & g.0NAME.aid = sAttrName
  then g.0TEXT.aid = sValue
  else call _addAttribute id,sAttrName,sValue
return

setAttributes: procedure expose g.
  parse arg id /* ,name1,value1,name2,value2,...,namen,valuen */
  do i = 2 to arg() by 2
    sAttrName = arg(i)
    sValue = arg(i+1)
    call setAttribute id,sAttrName,sValue
  end
return

removeAttribute: procedure expose g.
  parse arg id,sAttrName
  if \_canHaveAttributes(id)
  then call _abort,
            'XML022E' g.0NODETYPE.id 'node cannot have attributes:',
            'removeAttribute('id','sAttrName')'
  aid = g.0FIRSTATTR.id
  do while aid <> '' & g.0NAME.aid <> sAttrName
    aid = g.0NEXT.aid
  end
  if aid <> '' & g.0NAME.aid = sAttrName
  then do
    prevaid = g.0PREV.aid
    nextaid = g.0NEXT.aid
    if prevaid = ''  /* if we are deleting the first attribute */
    then g.0FIRSTATTR.id = nextaid /* make next attr the first */
    else g.0NEXT.prevaid = nextaid /* link prev attr to next attr */
    if nextaid = '' /* if we are deleting the last attribute */
    then g.0LASTATTR.id  = prevaid /* make prev attr the last */
    else g.0PREV.nextaid = prevaid /* link next attr to prev attr */
    call _clearNode aid
  end
return

toString: procedure expose g.
  parse arg node
  if node = '' then node = getRoot()
  if node = getRoot()
  then sXML = _getProlog()_getNode(node)
  else sXML = _getNode(node)
return sXML

_getProlog: procedure expose g.
  if g.?xml.version = ''
  then sVersion = '1.0'
  else sVersion = g.?xml.version
  if g.?xml.encoding = ''
  then sEncoding = 'UTF-8'
  else sEncoding = g.?xml.encoding
  if g.?xml.standalone = ''
  then sStandalone = 'yes'
  else sStandalone = g.?xml.standalone
  sProlog = '<?xml version="'sVersion'"',
            'encoding="'sEncoding'"',
            'standalone="'sStandalone'"?>'
return sProlog

_getNode: procedure expose g.
  parse arg node
  select
    when g.0TYPE.node = g.0ELEMENT_NODE then,
         sXML = _getElementNode(node)
    when g.0TYPE.node = g.0TEXT_NODE then,
         sXML = escapeText(removeWhitespace(getText(node)))
    when g.0TYPE.node = g.0ATTRIBUTE_NODE then,
         sXML = getName(node)'="'escapeText(getText(node))'"'
    when g.0TYPE.node = g.0CDATA_SECTION_NODE then,
         sXML = '<![CDATA['getText(node)']]>'
    otherwise sXML = '' /* TODO: throw an error here? */
  end
return sXML

_getElementNode: procedure expose g.
  parse arg node
  sName = getName(node)
  sAttrs = ''
  attr = g.0FIRSTATTR.node
  do while attr <> ''
    sAttrs = sAttrs _getNode(attr)
    attr = g.0NEXT.attr
  end
  if hasChildren(node)
  then do
    if sAttrs = ''
    then sXML = '<'sName'>'
    else sXML = '<'sName strip(sAttrs)'>'
    child = getFirstChild(node)
    do while child <> ''
      sXML = sXML || _getNode(child)
      child = getNextSibling(child)
    end
    sXML = sXML'</'sName'>'
  end
  else do
    if sAttrs = ''
    then sXML = '<'sName'/>'
    else sXML = '<'sName strip(sAttrs)'/>'
  end
return sXML

escapeText: procedure expose g.
  parse arg sText
  n = verify(sText,g.0ESCAPES,'MATCH')
  if n > 0
  then do
    sNewText = ''
    do while n > 0
      sLeft = ''
      n = n - 1
      if n = 0
      then parse var sText c +1 sText
      else parse var sText sLeft +(n) c +1 sText
      sNewText = sNewText || sLeft'&'g.0ESCAPE.c';'
      n = verify(sText,g.0ESCAPES,'MATCH')
    end
    sText = sNewText || sText
  end
return sText

/*-------------------------------------------------------------------*
 * SYSTEM "sysid"
 * PUBLIC "pubid" "sysid"
 *-------------------------------------------------------------------*/
setDocType: procedure expose g.
  parse arg sDocType
  g.0DOCTYPE = sDocType
return

getDocType: procedure expose g.
return g.0DOCTYPE

createComment: procedure expose g.
  parse arg sData
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0COMMENT_NODE
  g.0TEXT.id = sData
return id

deepClone: procedure expose g.
  parse arg node
return cloneNode(node,1)

cloneNode: procedure expose g.
  parse arg node,bDeep
  clone = _getNextId()
  call _clearNode clone
  g.0TYPE.clone = g.0TYPE.node
  g.0NAME.clone = g.0NAME.node
  g.0TEXT.clone = g.0TEXT.node
  /* clone any attributes...*/
  aidin = g.0FIRSTATTR.node
  do while aidin <> ''
    aid = _getNextId()
    g.0TYPE.aid = g.0TYPE.aidin
    g.0NAME.aid = g.0NAME.aidin
    g.0TEXT.aid = g.0TEXT.aidin
    g.0PARENT.aid = clone
    g.0NEXT.aid = ''
    g.0PREV.aid = ''
    if g.0FIRSTATTR.clone = '' then g.0FIRSTATTR.clone = aid
    if g.0LASTATTR.clone <> ''
    then do
      lastaid = g.0LASTATTR.clone
      g.0NEXT.lastaid = aid
      g.0PREV.aid = lastaid
    end
    g.0LASTATTR.clone = aid
    aidin = g.0NEXT.aidin
  end
  /* clone any children (if deep clone was requested)...*/
  if bDeep = 1
  then do
    childin = g.0FIRST.node /* first child of node being cloned */
    do while childin <> ''
      child = cloneNode(childin,bDeep)
      g.0PARENT.child = clone
      parentsLastChild = g.0LAST.clone
      g.0NEXT.parentsLastChild = child
      g.0PREV.child = parentsLastChild
      g.0LAST.clone = child
      if g.0FIRST.clone = ''
      then g.0FIRST.clone = child
      childin = g.0NEXT.childin /* next child of node being cloned */
    end
  end
return clone
