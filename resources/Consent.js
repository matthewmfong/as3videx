var submitted = false;
var noOfChecks = 0;

document.forms[0].onsubmit = function(e)
{
    e.preventDefault(); // Prevent submission
    submitForm();
};

document.forms[0].cancelbtn.onclick = function(e)
{
    document.forms[0].participate.checked = false;
    document.forms[0].reveal.checked = false;
    
    submitForm();
};

document.forms[0].participate.onclick = function(e)
{
   if(document.forms[0].participate.checked == true)
        noOfChecks = noOfChecks + 1;
    else
        noOfChecks = noOfChecks - 1;
    
    document.forms[0].submitbtn.disabled = (noOfChecks != 2);
    
};

document.forms[0].reveal.onclick = function(e)
{
    if(document.forms[0].reveal.checked == true)
        noOfChecks = noOfChecks + 1;
    else
        noOfChecks = noOfChecks - 1;
    
    document.forms[0].submitbtn.disabled = (noOfChecks != 2);
};


function submitForm()
{
    if(!submitted)
    {
        submitted = true;
    // send user's info to background.js to be logged
    chrome.runtime.getBackgroundPage(function(bgWindow) {
                                     bgWindow.setUserConsent(
                                                             document.forms[0].participate.checked,
                                                             document.forms[0].reveal.checked);
                                     
                                     window.close();     // Close dialog
                                     });
    }

}
// listen to tab/window close or navigate away from current tab/window
window.onbeforeunload = confirmExit;
function confirmExit()
{
    submitForm();
    return null;
}