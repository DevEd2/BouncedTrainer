PROJECTNAME=cpl-bncd

%.asm: ;
%.inc: ;
%.bin: ;
$(PROJECTNAME).gbc: %.asm %.inc %.bin gfx
	rgbasm -o $(PROJECTNAME).obj -p 255 Main.asm
	rgblink -p 255 -o $(PROJECTNAME).gbc -n $(PROJECTNAME).sym $(PROJECTNAME).obj
	rgbfix -v -p 255 $(PROJECTNAME).gbc
	md5sum $(PROJECTNAME).gbc

nogame: %.asm %.inc %.bin gfx
	rgbasm -o $(PROJECTNAME)-clean.obj -p 255 build-clean.asm
	rgblink -p 255 -o $(PROJECTNAME)-clean.gbc -n $(PROJECTNAME)-clean.sym $(PROJECTNAME)-clean.obj
	rgbfix -v -p 255 $(PROJECTNAME)-clean.gbc
	md5sum $(PROJECTNAME)-clean.gbc

play: $(PROJECTNAME).gbc
	/usr/bin/sameboy ./$(PROJECTNAME).gbc

gfx:
	./convbmp.sh

clean:
	find . -type f -name "*.gbc" -a -not -name "bounced.gbc" -delete
	find . -type f -name "*.sym" -delete
	find . -type f -name "*.obj" -delete
	