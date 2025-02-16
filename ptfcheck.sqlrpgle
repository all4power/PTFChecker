**FREE

 //-----------------------------------------------------------------------
 // Autore: Andrea Buzzi
 //-----------------------------------------------------------------------

 Ctl-Opt decedit('0,') datedit(*dmy.) DFTACTGRP(*NO);
 ctl-opt main(ptcheck);

 Dcl-PR runCmd ExtPgm('QCMDEXC');
  Command Char(500) Const;
  Length Packed(15:5) Const;
 END-PR;

 dcl-proc ptcheck;

// Inizio procedura principale.
  dcl-pi *N;
  end-pi;

  dcl-s ptffound int(10) inz(0);
  dcl-s ptfdef char(7) inz(*blank);
  dcl-s ptffix char(7) inz(*blank);
  dcl-s prod char(7) inz(*blank);
  dcl-s apar char(7) inz(*blank);
  dcl-s cmd varchar(1000) inz(*blank);
  dcl-s subj varchar(20) inz(*blank);
  dcl-s body varchar(1000) inz(*blank);

  EXEC SQL SET OPTION COMMIT = *NONE;
  EXEC SQL SET OPTION DATFMT = *ISO;
  EXEC SQL SET OPTION CLOSQLCSR = *ENDMOD; 
  
  //Preparing SNDPTFORD
  cmd='SNDPTFORD DLVRYFMT(*IMAGE) IMGCLG(PTFFIX) PTFID(';

  //Preparing mail report
  subj='Defective PTF report';
  body='<!doctype html><html><body style=''''color:black;font-family: '+
      'Arial, sans-serif;font-size: 14px;''''>'+
      'Here the list of defective PTFs found on the system:<br>';

  //Looking for defective PTFs with IBM sql service
  EXEC SQL DECLARE r0 CURSOR FOR 
    select DEFECTIVE_PTF,PRODUCT_ID,APAR_ID, 
    case when FIXING_PTF is null or FIXING_PTF='UNKNOWN' then '' else FIXING_PTF end as FIXING_PTF 
    from systools.DEFECTIVE_PTF_CURRENCY ;

  EXEC SQL OPEN r0;

  EXEC SQL FETCH from r0
      INTO :ptfdef, :prod, :apar, :ptffix;

  DOW SQLSTATE = '00000';

    //Adding ptf to order
    cmd='('+%trim(ptffix)+')';

    //Updating mail body
    body=%trim(body)+'- <b>PROD:</b> '+%trim(prod)+' <b>DEF PTF:</b> '+%trim(ptfdef)+
      ' <b>APAR:</b> '+%trim(apar)+' <b>FIX PTF:</b> '+%trim(ptffix)+'<br>';

    ptffound=ptffound+1;

    EXEC SQL FETCH from r0
      INTO :ptfdef, :prod, :apar, :ptffix;

  ENDDO;

  EXEC SQL CLOSE r0;

  cmd=%trim(cmd)+')';

  //If any def ptf found sndptford + send email
  if ptffound>0;
    runCmd(%trim(cmd):%len(%trim(cmd)));
    body=%trim(cmd)+'</body></html>';
    cmd='SNDSMTPEMM RCP((''andrea.all4power@gmail.com'')) SUBJECT('''+%trim(subj)+
      ''') NOTE('''+%trim(body)+''') CONTENT(*HTML)';
    runCmd(%trim(cmd):%len(%trim(cmd)));
  endif;

end-proc;

dcl-proc write_joblog;
  dcl-pi *n;
    message char(6000) const;
  END-PI;

  Exec SQL
    CALL SYSTOOLS.LPRINTF(trim(:message));
end-proc;
