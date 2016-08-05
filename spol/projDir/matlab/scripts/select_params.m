function selected_fields = select_params( rfields );

[Selection ok] = listdlg('ListSize',[400 400],'ListString',rfields );
selected_fields = { rfields{Selection}};
