import org.jvnet.hudson.plugins.thinbackup.ThinBackupPluginImpl;
import org.jvnet.hudson.plugins.thinbackup.ThinBackupPeriodicWork.BackupType;
import org.jvnet.hudson.plugins.thinbackup.backup.HudsonBackup;

new HudsonBackup(ThinBackupPluginImpl.getInstance(), BackupType.FULL).backup()
