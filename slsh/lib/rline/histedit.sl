% Public function: rline_edit_history
% Binding this function to a key will allow the history to be edited in 
% an external editor.
autoload ("new_process", "process");

variable RLine_Tmp_Dir;
private define open_tmp_file ()
{
   variable dir, dirs = ["/tmp", "$HOME"$];
   if (__is_initialized (&RLine_Tmp_Dir))
     dirs = [RLine_Tmp_Dir, dirs];

   foreach dir (dirs)
     {
	variable st = stat_file (dir);
	if (st == NULL)
	  continue;
	if (stat_is ("dir", st.st_mode))
	  break;
     }
   then dir = "";
   
   variable fmt = path_concat (dir, "histedit%X%d.tmp");
   variable pid = getpid ();
   variable n = 0;
   variable file, fp;

   loop (100)
     {
	n++;
	file = sprintf (fmt, pid*_time(), n);

	variable fd = open (file, O_WRONLY|O_CREAT|O_TRUNC|O_TEXT, S_IRUSR|S_IWUSR);
	if (fd == NULL)
	  return;

	fp = fdopen (fd, "w");
	if (fp != NULL)
	  return fp, fd, file;
     }
   throw OpenError, "Unable to open a temporary file";
}

private define get_editor ()
{
   variable editor = getenv("VISUAL");
   if (editor == NULL) editor = getenv ("EDITOR");
   if (editor == NULL) editor = "vi";
   return editor;
}

define rline_edit_history ()
{
   variable editor = get_editor ();
   variable file, fp, fd;
   (fp, fd, file) = open_tmp_file ();

   EXIT_BLOCK
     {
	() = remove (file);
     }

   () = array_map (Int_Type, &fputs, rline_get_history ()+"\n", fp);
   () = fclose (fp);

   variable st = stat_file (file);
   if (st == NULL)
     return;

   variable mtime = st.st_mtime;
  
   variable p = new_process ([editor, file]).wait();
   if ((p.exited == 0) || (p.exit_status != 0))
     return;
   
   st = stat_file (file);
   if ((st == NULL) || (st.st_mtime == mtime))
     return;

   fp = fopen (file, "r");
   if (fp == NULL)
     return;
   
   variable lines = fgetslines (fp);
   () = fclose (fp);

   if (length (lines) == 0)
     return;

   rline_set_history (array_map (String_Type, &strtrim_end, lines, "\n"));
}
