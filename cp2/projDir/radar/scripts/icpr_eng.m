<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>

<head>
<link rel="stylesheet" type="text/css" href="/mail/themes/css/sans-12.css" />
<title>SquirrelMail</title><script language="JavaScript" type="text/javascript">
<!--
function checkForm() {
var f = document.forms.length;
var i = 0;
var pos = -1;
while( pos == -1 && i < f ) {
var e = document.forms[i].elements.length;
var j = 0;
while( pos == -1 && j < e ) {
if ( document.forms[i].elements[j].type == 'text' || document.forms[i].elements[j].type == 'password' ) {
pos = j;
}
j++;
}
i++;
}
if( pos >= 0 ) {
document.forms[i-1].elements[pos].focus();
}

}
function comp_in_new(comp_uri) {
       if (!comp_uri) {
           comp_uri = "/mail/src/compose.php?newmessage=1";
       }
    var newwin = window.open(comp_uri, "_blank","width=900,height=700,scrollbars=yes,resizable=yes,status=yes");
}

// -->
</script>

<style type="text/css">
<!--
  /* avoid stupid IE6 bug with frames and scrollbars */
  body {
      voice-family: "\"}\"";
      voice-family: inherit;
      width: expression(document.documentElement.clientWidth - 30);
  }
-->
</style>

</head>

<body text="#000000" bgcolor="#DEDFDF" link="#0000CC" vlink="#0000CC" alink="#0000CC" onload="checkForm();">

<a name="pagetop"></a>
<table bgcolor="#DEDFDF" border="0" width="100%" cellspacing="0" cellpadding="2">

<tr bgcolor="#ABABAB">

<td align="left">

&nbsp;      </td>
<td align="right">
<b>
<a href="/mail/src/signout.php" target="_top">Sign Out</a></b></td>
   </tr>
<tr bgcolor="#DEDFDF">

<td align="left">

<a href="javascript:void(0)" onclick="comp_in_new('/mail/src/compose.php?mailbox=None&amp;startMessage=0')">Compose</a>&nbsp;&nbsp;
<a href="/mail/src/addressbook.php">Addresses</a>&nbsp;&nbsp;
<a href="/mail/src/folders.php">Folders</a>&nbsp;&nbsp;
<a href="/mail/src/options.php">Options</a>&nbsp;&nbsp;
<a href="/mail/src/search.php?mailbox=None">Search</a>&nbsp;&nbsp;
<a href="/mail/src/help.php">Help</a>&nbsp;&nbsp;
      </td>
<td align="right">

<a href="http://www.squirrelmail.org/" target="_blank">SquirrelMail</a></td>
   </tr>
</table><br>

<br /><table width="100%" border="0" cellspacing="0" cellpadding="2" align="center"><tr><td bgcolor="#A8A8A8">
<b><center>
Viewing a text attachment - <a href="read_body.php?mailbox=INBOX&passed_id=14171&startMessage=1">View message</a></b></td><tr><tr><td><center>
<a href="../src/download.php?mailbox=INBOX&passed_id=14171&startMessage=1&ent_id=2&amp;absolute_dl=true">Download this as a file</a></center><br />
</center></b>
</td></tr></table>
<table width="98%" border="0" cellspacing="0" cellpadding="2" align="center"><tr><td bgcolor="#A8A8A8">
<tr><td bgcolor="#DEDFDF"><tt>
<pre>%% 20060707, 20060710, 20060721 PP
%%
%% Pekka Puhakka, Univ. of Helsinki
%%
%% Computing the ICPR and ZDR bias from
%% the antenna pattern data as described in
%% &quot;Chandra &amp; Keeler 1993&quot;, page 677.
%%

% Selecting the angular limits for
% the area to be included into
% calculation

az_min = -10;
az_max = 10;    %%%askellushommeli
el_min = -3;    %%%-0.2*(i-1);
el_max = 10;     

% Loading the data

load AntGridData.mat

% Centering the co-ordinate system into the beam axis

az = az - 270.8;
el = el - 1.8;

% lasketaan elevaatiomuuttujasta meshgrid-data
% integrointien cos(elevaatio)-termi? varten.
% 1.8 korjaa koordinaatiston keskityksen takaisin.

% Computing meshgrid data from the elevation angles
% for cos(elevation) term in the integration.
% 1.8 is in order to fix the co-ordinate
% centerizing back.

[azm,elm] = meshgrid(az,el);
elm = pi * (elm + 1.8)/180;
                             
% Normalizing the powers (max = 0 dB)

P_HH = P_HH - max(max(P_HH));
P_VH = P_VH - max(max(P_HH));
P_VV = P_VV - max(max(P_VV));
P_HV = P_HV - max(max(P_VV));

% Linearizing

P_HH = 10.^(P_HH/10);
P_HV = 10.^(P_HV/10);
P_VV = 10.^(P_VV/10);
P_VH = 10.^(P_VH/10);

% Taking square root of the
% power in order to get it into
% electric field amplitude

P_HH = P_HH.^(1/2);
P_HV = P_HV.^(1/2);
P_VV = P_VV.^(1/2);
P_VH = P_VH.^(1/2);

% Picking up the selected are from the 
% radiation pattern (defined at the beginning of
% this program with az_min, _max etc.

azl = find(az &gt; az_min &amp; az &lt; az_max);
ell = find(el &gt; el_min &amp; el &lt; el_max);

azl_min = min(azl);
azl_max = max(azl);
ell_min = min(ell);
ell_max = max(ell);

P_HH = P_HH(ell_min:ell_max,azl_min:azl_max);
P_VH = P_VH(ell_min:ell_max,azl_min:azl_max);
P_VV = P_VV(ell_min:ell_max,azl_min:azl_max);
P_HV = P_HV(ell_min:ell_max,azl_min:azl_max);
az   = az(azl_min:azl_max);
el   = el(ell_min:ell_max);
azm  = azm(ell_min:ell_max,azl_min:azl_max);
elm  = elm(ell_min:ell_max,azl_min:azl_max);

% Computing the lower limit for the icpr

osoit = cos(elm).*(P_VH.*P_HH - P_VV.*P_HV).^2;
nimit = cos(elm).*(P_HH.^2 + P_HV.^2).^2;
osoit = sum(sum(osoit));
nimit = sum(sum(nimit));
osam  = osoit/nimit;
icpr_min  = 10*log10(osam)

% Upper limit for the icpr

osoit = cos(elm).*(P_VH.*P_HH + P_VV.*P_HV).^2;
nimit = cos(elm).*(P_HH.^2 - P_HV.^2).^2;
osoit = sum(sum(osoit));
nimit = sum(sum(nimit));
osam  = osoit/nimit;
icpr_max  = 10*log10(osam)

% Lower limit for the ZDR bias

osoit = cos(elm).*(P_HH.^2 - P_HV.^2).^2;
nimit = cos(elm).*(P_VV.^2 + P_VH.^2).^2;
osoit = sum(sum(osoit));
nimit = sum(sum(nimit));
osam  = osoit/nimit;
zdrb_min  = 10*log10(osam)

% Upper limit for the ZDR bias

osoit = cos(elm).*(P_HH.^2 + P_HV.^2).^2;
nimit = cos(elm).*(P_VV.^2 - P_VH.^2).^2;
osoit = sum(sum(osoit));
nimit = sum(sum(nimit));
osam  = osoit/nimit;
zdrb_max  = 10*log10(osam)

% Plotting the selected area (P_HH data),
% this is only for cross checking the are limits.

contourf(az,el,10*log10(P_HH))
colorbar

%

</pre></tt></td></tr></table>
</body></html>
