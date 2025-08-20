function plot_budg(frun)

% Set EMU output directory
frun_output = fullfile(frun, 'output');

% Budget labels
fbudg = {'volume', 'heat', 'salt', 'salinity', 'momentum'};

% ---------- Read Tendency ----------
ff = fullfile(frun_output, 'emu_budg.sum_tend');
[emubudg_name, emubudg, lhs_tend, rhs_tend, adv_tend, mix_tend, frc_tend, nvar, ibud, ~] = rd_budg_sum(ff);
emu.budg_tend = emubudg;
emu.budg_tend_name = emubudg_name;
fprintf('* Read tend: %s\n', ff);

% ---------- Read Time-Integrated ----------
ff = fullfile(frun_output, 'emu_budg.sum_tint');
[emubudg_name, emubudg, lhs_tint, rhs_tint, adv_tint, mix_tint, frc_tint, ~, ~, ~] = rd_budg_sum(ff);
emu.budg_tint = emubudg;
emu.budg_tint_name = emubudg_name;
fprintf('* Read tint: %s\n', ff);

% ---------- Read Masks ----------
[emubudg_name, emubudg] = rd_budg_msk(frun_output);
emu.budg_msk = emubudg;
emu.budg_msk_name = emubudg_name;
fprintf('* Read masks from emu_budg.msk3d_*\n');

% ---------- Read Makeup ----------
[emubudg_name, emubudg] = rd_budg_mkup(frun_output);
emu.budg_mkup = emubudg;
emu.budg_mkup_name = emubudg_name;
fprintf('* Read mkup from emu_budg.mkup_*\n');

% ---------- Plotting ----------
nmonths = length(lhs_tint);
tt = (0:nmonths-1) / 12 + 1992;  % Assuming Jan 1992 start

nplot = 2 + (nvar - 2) + 3;
npx = ceil(nplot / 2);
figure;
ip = 1;

% Plot LHS vs RHS (tend)
subplot(npx, 2, ip); ip = ip + 1;
plot(tt, lhs_tend, 'k', 'LineWidth', 2); hold on;
plot(tt, rhs_tend, 'r');
plot(tt, lhs_tend - rhs_tend, 'c');
title(sprintf('%s (tend)', fbudg{ibud}));
legend('LHS', 'RHS', 'LHS-RHS');

% Plot LHS vs RHS (tint)
subplot(npx, 2, ip); ip = ip + 1;
plot(tt, lhs_tint, 'k', 'LineWidth', 2); hold on;
plot(tt, rhs_tint, 'r');
plot(tt, lhs_tint - rhs_tint, 'c');
title(sprintf('%s (tint)', fbudg{ibud}));
legend('LHS', 'RHS', 'LHS-RHS');

%% Plot individual terms (tend) vs sum of mkup fluxes
%for ivar = 3:nvar
%    subplot(npx, 2, ip); ip = ip + 1;
%
%    % Find all mkup fluxes assigned to this ivar
%    mkup_sum = zeros(size(tt));
%    for j = 1:length(emu.budg_mkup)
%        if emu.budg_mkup(j).isum == ivar
%            mkup_sum = mkup_sum + emu.budg_mkup(j).mkup(:)
%        end
%    end
%
%    plot(tt, emu.budg_tend(ivar, :), 'k', 'LineWidth', 2); hold on;
%    plot(tt, mkup_sum, 'b');
%    title(sprintf('%s: sum vs mkup', emu.budg_tend_name{ivar}));
%    legend('sum_tend', 'sum_mkup');
%end
%
%% Plot individual terms (tint)
%for ivar = 1:3
%    subplot(npx, 2, ip); ip = ip + 1;
%    plot(tt, emu.budg_tint(ivar, :));
%    title(sprintf('%s (tint)', emu.budg_tint_name{ivar}));
%end

keyboard
end
